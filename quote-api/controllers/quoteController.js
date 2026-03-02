const { pool } = require('../config/database');
const CalculationService = require('../services/calculationService');
const AppError = require('../utils/AppError');

class QuoteController {
  async getAll(req, res, next) {
    try {
      const [rows] = await pool.query(`
        SELECT q.*, u.username AS created_by_name
        FROM quotations q
        LEFT JOIN users u ON q.created_by = u.id
        ORDER BY q.created_at DESC
      `);
      res.json({ success: true, data: rows });
    } catch (err) {
      next(err);
    }
  }

  async getByQuoteNo(req, res, next) {
    try {
      const { quote_no } = req.params;
      const [quotes] = await pool.query(`
        SELECT q.*, u.username AS created_by_name
        FROM quotations q
        LEFT JOIN users u ON q.created_by = u.id
        WHERE q.quote_no = ?
      `, [quote_no]);

      if (!quotes.length) throw new AppError('Quotation not found', 404);

      const [items] = await pool.query(`
        SELECT * FROM quotation_items
        WHERE quotation_id = ?
        ORDER BY item_no ASC
      `, [quotes[0].id]);

      res.json({ success: true, data: { ...quotes[0], items } });
    } catch (err) {
      next(err);
    }
  }

  async getEquipment(req, res, next) {
    try {
      const [equipment] = await pool.query('SELECT * FROM equipment_types');
      if (!equipment.length) throw new AppError('No equipment found', 404);

      const [rows] = await pool.query(`
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
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new QuoteController();