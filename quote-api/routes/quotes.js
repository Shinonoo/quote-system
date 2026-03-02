const express = require('express');
const router = express.Router();

const asyncWrapper = require('../utils/asyncWrapper');
const AppError = require('../utils/AppError');
const db = require('../db');

// ─── GET /equipment ───────────────────────────────────────────────────────────

router.get('/equipment', asyncWrapper(async (req, res) => {
  const [equipment] = await db.query('SELECT * FROM equipment_types');
  if (!equipment.length) throw new AppError('No equipment found', 404);

  // ✅ Join customizations to get key_name per equipment
  const [rows] = await db.query(`
    SELECT ec.equipment_type_id, c.key_name
    FROM equipment_customizations ec
    JOIN customizations c ON ec.customization_id = c.id
  `);

  const result = equipment.map(eq => {
    const allowed = rows
      .filter(r => r.equipment_type_id === eq.id)
      .map(r => r.key_name);
    return { ...eq, allowed_customizations: allowed };
  });

  res.json({ success: true, data: result });
}));

// ─── GET / (all quotations) ───────────────────────────────────────────────────

router.get('/', asyncWrapper(async (req, res) => {
  const [rows] = await db.query(`
    SELECT q.*, u.username AS created_by_name
    FROM quotations q
    LEFT JOIN users u ON q.created_by = u.id
    ORDER BY q.created_at DESC
  `);
  res.json({ success: true, data: rows });
}));

// ─── GET /:quote_no (single quotation with items) ─────────────────────────────

router.get('/:quote_no', asyncWrapper(async (req, res) => {
  const { quote_no } = req.params;

  const [quotes] = await db.query(`
    SELECT q.*, u.username AS created_by_name
    FROM quotations q
    LEFT JOIN users u ON q.created_by = u.id
    WHERE q.quote_no = ?
  `, [quote_no]);

  if (!quotes.length) throw new AppError('Quotation not found', 404);

  const quotation = quotes[0];

  // ✅ quotation_items uses quotation_id (not quote_no)
  const [items] = await db.query(`
    SELECT * FROM quotation_items
    WHERE quotation_id = ?
    ORDER BY item_no ASC
  `, [quotation.id]);

  res.json({ success: true, data: { ...quotation, items } });
}));

// ─── POST /create ─────────────────────────────────────────────────────────────

router.post('/create', asyncWrapper(async (req, res) => {
  const {
    company_name, company_location,
    attention_name, attention_position,
    customer_project, project_location,
    created_by, items
  } = req.body;

  if (!company_name || !customer_project || !items?.length) {
    throw new AppError('company_name, customer_project, and items are required', 400);
  }

  // ── Generate reference number ──
  const now = new Date();
  const pad = (n) => String(n).padStart(2, '0');
  const quote_no = `QT-${Date.now()}`;

  // ✅ Use user prefix from DB for reference_no
  const [userRows] = await db.query('SELECT prefix FROM users WHERE id = ?', [created_by]);
  const prefix = userRows.length ? userRows[0].prefix || 'GT' : 'GT';
  const reference_no = `${prefix}-${now.getFullYear()}-${pad(now.getMonth() + 1)}${pad(now.getDate())}-${Date.now().toString().slice(-3)}`;

  let grand_total = 0;
  const processedItems = [];

  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    const { equipment_type_id, item_code, length, width, qty, customizations } = item;

    let raw_unit_price = 0;
    let description = 'Custom Equipment';

    // ── Custom entry (-1) ──
    if (equipment_type_id === -1) {
      raw_unit_price = parseFloat(customizations?.custom_price ?? 0);
      description = customizations?.custom_desc ?? 'Custom Equipment';
    } else {
      const [eqRows] = await db.query('SELECT * FROM equipment_types WHERE id = ?', [equipment_type_id]);
      if (!eqRows.length) throw new AppError(`Equipment ID ${equipment_type_id} not found`, 404);

      const eq = eqRows[0];
      const area = parseFloat(length) * parseFloat(width);

      // ✅ Correct formula using your actual columns
      raw_unit_price = (area / parseFloat(eq.base_divisor))
        * parseFloat(eq.base_multiplier)
        * parseFloat(eq.final_multiplier);

      description = eq.name;
    }

    // ── Apply customization multipliers ──
    let multiplier = 1.0;
    if (customizations) {
      if (customizations.insect_screen) multiplier *= parseFloat(customizations.insect_screen);
      if (customizations.bird_screen)   multiplier *= parseFloat(customizations.bird_screen);
      if (customizations.obvd)          multiplier *= parseFloat(customizations.obvd);
      if (customizations.radial_damper) multiplier *= parseFloat(customizations.radial_damper);
      if (customizations.double_frame)  multiplier *= parseFloat(customizations.double_frame);
      if (customizations.powder_coat)   raw_unit_price += parseFloat(customizations.powder_coat?.price ?? 500);
    }

    const final_unit_price = raw_unit_price * multiplier;
    const line_total = final_unit_price * parseInt(qty);
    grand_total += line_total;

    processedItems.push({
      description,
      item_code,
      length,
      width,
      qty,
      customizations: JSON.stringify(customizations ?? {}),
      raw_unit_price: raw_unit_price.toFixed(2),
      discount_type: item.discount_type ?? 'none',
      discount_value: item.discount_value ?? 0,
      final_unit_price: final_unit_price.toFixed(2),
      line_total: line_total.toFixed(2),
    });
  }

  // ── Save quotation header ──
  // ✅ customer_name is NOT NULL in your schema — use company_name as fallback
  const [result] = await db.query(`
    INSERT INTO quotations 
      (quote_no, reference_no, customer_name, company_name, company_location,
       attention_name, attention_position, customer_project, project_location,
       grand_total, created_by)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
  `, [
    quote_no, reference_no, company_name, company_name, company_location,
    attention_name, attention_position, customer_project, project_location,
    grand_total.toFixed(2), created_by
  ]);

  const quotation_id = result.insertId;

  // ── Save all items ──
  // ✅ Uses quotation_id + item_no, matches your actual schema
  for (let i = 0; i < processedItems.length; i++) {
    const item = processedItems[i];
    await db.query(`
      INSERT INTO quotation_items 
        (quotation_id, item_no, description, item_code, length, width,
         customizations, raw_unit_price, discount_type, discount_value,
         final_unit_price, qty, line_total)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [
      quotation_id, i + 1, item.description, item.item_code,
      item.length, item.width, item.customizations, item.raw_unit_price,
      item.discount_type, item.discount_value, item.final_unit_price,
      item.qty, item.line_total
    ]);
  }

  res.status(201).json({ success: true, quote_no, reference_no, grand_total: grand_total.toFixed(2) });
}));

module.exports = router;
