const express = require('express');
const router = express.Router();

const CalculationService = require('../services/calculationService');
const asyncWrapper        = require('../utils/asyncWrapper');
const AppError            = require('../utils/AppError');
const { pool }            = require('../config/database');
const quoteController     = require('../controllers/quoteController');

// ─── Bind controller methods ──────────────────────────────────
const ctrl = {
  getAll:           quoteController.getAll.bind(quoteController),
  getByReferenceNo: quoteController.getByReferenceNo.bind(quoteController),
  getByQuoteNo:     quoteController.getByQuoteNo.bind(quoteController),
  getEquipment:     quoteController.getEquipment.bind(quoteController),
  updateStatus:     quoteController.updateStatus.bind(quoteController),
};

// ─── GET Routes ───────────────────────────────────────────────
router.get('/equipment',    asyncWrapper(ctrl.getEquipment));
router.get('/',             asyncWrapper(ctrl.getAll));
router.get('/ref/:ref_no',  asyncWrapper(ctrl.getByReferenceNo));
router.get('/:ref_no',      asyncWrapper(ctrl.getByQuoteNo));

// ─── PUT Routes ───────────────────────────────────────────────
router.put('/:ref_no/status', asyncWrapper(ctrl.updateStatus));

// ─── POST /create ─────────────────────────────────────────────
router.post('/create', asyncWrapper(async (req, res) => {
  const {
    company_name,
    company_location,
    attention_name,
    attention_position,
    customer_project,
    project_location,
    created_by,
    items,
  } = req.body;

  if (!company_name || !customer_project || !items?.length) {
    throw new AppError('company_name, customer_project, and items are required', 400);
  }

  if (!created_by) {
    throw new AppError('created_by (user id) is required', 400);
  }

  const conn = await pool.getConnection();

  try {
    await conn.beginTransaction();

    // Pull prefix + seq atomically
    const [[settings]] = await conn.query(
      'SELECT quote_prefix, next_quote_seq, vat_rate FROM settings WHERE id = 1 FOR UPDATE'
    );
    const { quote_prefix, next_quote_seq, vat_rate } = settings;
    const ref_no = `${quote_prefix}-${String(next_quote_seq).padStart(4, '0')}`;

    // Verify user exists and is active
    const [[user]] = await conn.query(
      'SELECT id FROM users WHERE id = ? AND is_active = 1', [created_by]
    );
    if (!user) throw new AppError('Invalid or inactive user', 400);

    let subtotal = 0;
    const processedItems = [];

    // ─── Process each item ────────────────────────────────
    for (let i = 0; i < items.length; i++) {
      const item = items[i];

      if (item.unit_price !== undefined) {
        // ── FRONTEND FORMAT (pre-calculated from Flutter) ─

        const qty       = parseInt(item.qty) || 1;
        const unitPrice = parseFloat(item.unit_price) || 0;
        const lineTotal = unitPrice * qty;
        subtotal += lineTotal;

        // ✅ Round product: Flutter sends inch_size (e.g. 6) instead of neck_size
        // ✅ Rect product:  Flutter sends neck_size  (e.g. "600mm x 400mm")
        let itemWidth  = 0;
        let itemHeight = 0;
        let inchSize   = null;

        if (item.inch_size != null && item.inch_size !== undefined) {
          // Round product — store inch_size, width/height stay 0
          inchSize = parseInt(item.inch_size) || null;
        } else if (item.neck_size) {
          // Rectangular product — parse "600mm x 400mm"
          const match = item.neck_size.match(/(\d+)mm?\s*x\s*(\d+)mm?/i);
          itemWidth  = match ? parseInt(match[1]) : 0;
          itemHeight = match ? parseInt(match[2]) : 0;
        }

        // Build customizations object
        const customizations = {};
        if (item.material) customizations.material = item.material;
        if (item.customizations) {
          if (Array.isArray(item.customizations)) {
            item.customizations.forEach(c => { customizations[c] = true; });
          } else {
            Object.assign(customizations, item.customizations);
          }
        }

        processedItems.push({
          product_id:      null,
          product_model:   item.item_code   || '',
          product_name:    item.description || 'Custom Item',
          material:        item.material    || '',
          width:           itemWidth,
          height:          itemHeight,
          inch_size:       inchSize,                    // ✅ round products
          customizations:  JSON.stringify(customizations),
          quantity:        qty,
          raw_unit_price:  unitPrice.toFixed(2),
          discount_type:   'none',
          discount_amount: 0,
          unit_price:      unitPrice.toFixed(2),
          total_price:     lineTotal.toFixed(2),
          sort_order:      i + 1,
        });

      } else {
        // ── BACKEND FORMAT (product id) ───────────────────
        const { equipment_type_id, length, width, qty, customizations } = item;

        let productData = null;
        if (equipment_type_id !== -1) {
          const [rows] = await conn.query(
            'SELECT * FROM products WHERE id = ? AND is_active = 1', [equipment_type_id]
          );
          if (!rows.length) throw new AppError(`Product ID ${equipment_type_id} not found`, 404);
          productData = rows[0];
        }

        const calc      = CalculationService.calculateLineItem(
          equipment_type_id, length, width, customizations, productData
        );
        const lineTotal = calc.final_unit_price * parseInt(qty);
        subtotal += lineTotal;

        processedItems.push({
          product_id:      equipment_type_id !== -1 ? equipment_type_id : null,
          product_model:   item.item_code || productData?.model || '',
          product_name:    calc.description,
          material:        customizations?.material || '',
          width:           length,
          height:          width,
          inch_size:       null,
          customizations:  JSON.stringify(customizations ?? {}),
          quantity:        parseInt(qty),
          raw_unit_price:  calc.raw_unit_price.toFixed(2),
          discount_type:   item.discount_type === 'percentage' ? 'percent' : (item.discount_type ?? 'none'),
          discount_amount: item.discount_value ?? 0,
          unit_price:      calc.final_unit_price.toFixed(2),
          total_price:     lineTotal.toFixed(2),
          sort_order:      i + 1,
        });
      }
    }

    // ─── Financials ───────────────────────────────────────
    const vat_amount   = parseFloat(((subtotal * vat_rate) / 100).toFixed(2));
    const total_amount = parseFloat((subtotal + vat_amount).toFixed(2));

    // ─── Insert quotation ─────────────────────────────────
    const [result] = await conn.query(`
      INSERT INTO quotations (
        ref_no,
        customer_name,       customer_company,
        attention_name,      attention_position,
        supply_description,
        company_location,    project_location,
        subtotal,            discount_amount,
        vat_rate,            vat_amount,         total_amount,
        status,              created_by
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, 'draft', ?)
    `, [
      ref_no,
      company_name,            company_name,
      attention_name  ?? null, attention_position ?? null,
      customer_project,
      company_location ?? null, project_location ?? null,
      subtotal.toFixed(2),
      vat_rate, vat_amount, total_amount,
      created_by,
    ]);

    const quotation_id = result.insertId;

    // ─── Insert items ─────────────────────────────────────
    for (const item of processedItems) {
      await conn.query(`
        INSERT INTO quotation_items (
          quotation_id,
          product_id,      product_model,   product_name,
          material,        width,           height,          inch_size,
          customizations,
          quantity,        raw_unit_price,  discount_type,
          discount_amount, unit_price,      total_price,
          sort_order
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      `, [
        quotation_id,
        item.product_id,      item.product_model,  item.product_name,
        item.material,        item.width,          item.height,         item.inch_size,
        item.customizations,
        item.quantity,        item.raw_unit_price, item.discount_type,
        item.discount_amount, item.unit_price,     item.total_price,
        item.sort_order,
      ]);
    }

    // Increment seq only after full success
    await conn.query(
      'UPDATE settings SET next_quote_seq = next_quote_seq + 1 WHERE id = 1'
    );

    await conn.commit();

    res.status(201).json({
      success:      true,
      ref_no,
      quotation_id,
      quote_no:     ref_no,  // Flutter compat
      reference_no: ref_no,  // Flutter compat
      total_amount: total_amount.toFixed(2),
      grand_total:  total_amount.toFixed(2), // Flutter compat
    });

  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}));

module.exports = router;