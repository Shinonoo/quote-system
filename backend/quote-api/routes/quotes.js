const express = require('express');
const router = express.Router();

const CalculationService = require('../services/calculationService');
const asyncWrapper = require('../utils/asyncWrapper');
const AppError = require('../utils/AppError');
const { pool } = require('../config/database');
const quoteController = require('../controllers/quoteController');

// ─── GET Routes ─────────────────────────────────────────
router.get('/equipment', asyncWrapper(quoteController.getEquipment));
router.get('/', asyncWrapper(quoteController.getAll));
router.get('/ref/:reference_no', asyncWrapper(quoteController.getByReferenceNo));
router.get('/:quote_no', asyncWrapper(quoteController.getByQuoteNo));

// ─── PUT Routes ─────────────────────────────────────────
router.put('/:quote_no/status', asyncWrapper(quoteController.updateStatus));

// ─── POST /create ─────────────────────────────────────────────────────────────
router.post('/create', asyncWrapper(async (req, res) => {
  const {
    company_name, company_location,
    attention_name, attention_position,
    customer_project, project_location,
    created_by, items
  } = req.body;

  // Validation
  if (!company_name || !customer_project || !items?.length) {
    throw new AppError('company_name, customer_project, and items are required', 400);
  }

  // Get user's prefix for reference number
  let userPrefix = 'GT';
  if (created_by) {
    const [users] = await pool.query('SELECT prefix FROM users WHERE id = ?', [created_by]);
    if (users.length && users[0].prefix) {
      userPrefix = users[0].prefix;
    }
  }

  // Generate numbers using service
  const quote_no = CalculationService.generateQuoteNumber();
  const reference_no = CalculationService.generateReferenceNumber(userPrefix);

  let grand_total = 0;
  const processedItems = [];

  // Process each item
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    
    // Check if this is a pre-calculated item from the frontend
    // Frontend sends: description, neck_size, qty, unit_price, material
    // Backend expects: equipment_type_id, length, width, qty, customizations
    if (item.unit_price !== undefined && item.neck_size !== undefined) {
      // ===== FRONTEND FORMAT (pre-calculated) =====
      // Parse neck_size like "600mm x 400mm" to extract length and width
      const neckSizeMatch = item.neck_size.match(/(\d+)mm?\s*x\s*(\d+)mm?/i);
      const length = neckSizeMatch ? parseInt(neckSizeMatch[1]) : 0;
      const width = neckSizeMatch ? parseInt(neckSizeMatch[2]) : 0;
      
      const qty = parseInt(item.qty) || 1;
      const unitPrice = parseFloat(item.unit_price) || 0;
      const line_total = unitPrice * qty;
      grand_total += line_total;

      // Build customizations object from material and other fields
      const customizations = {};
      if (item.material) {
        customizations.material = item.material;
      }
      if (item.customizations) {
        // If frontend sends customizations array, convert to object
        if (Array.isArray(item.customizations)) {
          item.customizations.forEach(c => {
            customizations[c] = true;
          });
        } else {
          Object.assign(customizations, item.customizations);
        }
      }

      processedItems.push({
        description: item.description || 'Custom Item',
        item_code: item.item_code || '',
        length: length,
        width: width,
        qty: qty,
        customizations: JSON.stringify(customizations),
        raw_unit_price: unitPrice.toFixed(2),
        discount_type: 'none',
        discount_value: 0,
        final_unit_price: unitPrice.toFixed(2),
        line_total: line_total.toFixed(2),
      });
    } else {
      // ===== BACKEND FORMAT (with equipment_type_id) =====
      const { equipment_type_id, length, width, qty, customizations } = item;

      let equipmentData = null;

      // Fetch equipment if not custom
      if (equipment_type_id !== -1) {
        const [eqRows] = await pool.query('SELECT * FROM equipment_types WHERE id = ?', [equipment_type_id]);
        if (!eqRows.length) throw new AppError(`Equipment ID ${equipment_type_id} not found`, 404);
        equipmentData = eqRows[0];
      }

      // Use service to calculate
      const calc = CalculationService.calculateLineItem(
        equipment_type_id, length, width, customizations, equipmentData
      );

      const line_total = calc.final_unit_price * parseInt(qty);
      grand_total += line_total;

      processedItems.push({
        description: calc.description,
        item_code: item.item_code || equipmentData?.code || '',
        length: length,
        width: width,
        qty: qty,
        customizations: JSON.stringify(customizations ?? {}),
        raw_unit_price: calc.raw_unit_price.toFixed(2),
        discount_type: item.discount_type === 'percentage' ? 'percent' : (item.discount_type ?? 'none'),
        discount_value: item.discount_value ?? 0,
        final_unit_price: calc.final_unit_price.toFixed(2),
        line_total: line_total.toFixed(2),
      });
    }
  }

  // Save quotation header (matching user's schema)
  const [result] = await pool.query(`
    INSERT INTO quotations 
      (quote_no, reference_no, customer_name, company_name, company_location,
       attention_name, attention_position, customer_project, project_location,
       grand_total, created_by, quote_date)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, CURDATE())
  `, [
    quote_no, reference_no, company_name, company_name, company_location,
    attention_name, attention_position, customer_project, project_location,
    grand_total.toFixed(2), created_by
  ]);

  const quotation_id = result.insertId;

  // Save items
  for (let i = 0; i < processedItems.length; i++) {
    const item = processedItems[i];
    await pool.query(`
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

  res.status(201).json({ 
    success: true, 
    quote_no, 
    reference_no, 
    grand_total: grand_total.toFixed(2) 
  });
}));

module.exports = router;
