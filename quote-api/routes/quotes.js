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
router.get('/:quote_no', asyncWrapper(quoteController.getByQuoteNo));

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

  // Generate numbers using service
  const quote_no = CalculationService.generateQuoteNumber();
  const reference_no = CalculationService.generateReferenceNumber();

  let grand_total = 0;
  const processedItems = [];

  // Process each item using CalculationService
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
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
      length,
      width,
      qty,
      customizations: JSON.stringify(customizations ?? {}),
      raw_unit_price: calc.raw_unit_price.toFixed(2),
      discount_type: item.discount_type ?? 'none',
      discount_value: item.discount_value ?? 0,
      final_unit_price: calc.final_unit_price.toFixed(2),
      line_total: line_total.toFixed(2),
    });
  }

  // Save quotation header
  const [result] = await pool.query(`
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