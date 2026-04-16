const { pool } = require('../config/database');
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

      for (let row of rows) {
        const [items] = await pool.query(`
          SELECT * FROM quotation_items
          WHERE quotation_id = ?
          ORDER BY sort_order ASC
        `, [row.id]);
        row.items = items;
      }

      res.json({ success: true, data: rows });
    } catch (err) {
      next(err);
    }
  }

  async getByQuoteNo(req, res, next) {
    try {
      const { ref_no } = req.params;
      const [quotes] = await pool.query(`
        SELECT q.*, u.username AS created_by_name
        FROM quotations q
        LEFT JOIN users u ON q.created_by = u.id
        WHERE q.ref_no = ?
      `, [ref_no]);

      if (!quotes.length) throw new AppError('Quotation not found', 404);

      const [items] = await pool.query(`
        SELECT * FROM quotation_items
        WHERE quotation_id = ?
        ORDER BY sort_order ASC
      `, [quotes[0].id]);

      res.json({ success: true, data: { ...quotes[0], items } });
    } catch (err) {
      next(err);
    }
  }

  async getByReferenceNo(req, res, next) {
    try {
      const { ref_no } = req.params;
      const [quotes] = await pool.query(`
        SELECT q.*, u.username AS created_by_name
        FROM quotations q
        LEFT JOIN users u ON q.created_by = u.id
        WHERE q.ref_no = ?
      `, [ref_no]);

      if (!quotes.length) throw new AppError('Quotation not found', 404);

      const [items] = await pool.query(`
        SELECT * FROM quotation_items
        WHERE quotation_id = ?
        ORDER BY sort_order ASC
      `, [quotes[0].id]);

      res.json({ success: true, data: { ...quotes[0], items } });
    } catch (err) {
      next(err);
    }
  }

  async getEquipment(req, res, next) {
    try {
      const [products] = await pool.query(
        `SELECT * FROM products WHERE is_active = 1 ORDER BY category, name`
      );
      if (!products.length) throw new AppError('No products found', 404);

      // Parse JSON fields so Flutter receives proper arrays/objects
      const result = products.map(p => ({
        ...p,
        materials:       JSON.parse(p.materials       || '[]'),
        customizations:  JSON.parse(p.customizations  || '[]'),
        multipliers:     JSON.parse(p.multipliers      || '{}'),
        round_prices:    p.round_prices ? JSON.parse(p.round_prices) : null,
      }));

      res.json({ success: true, data: result });
    } catch (err) {
      next(err);
    }
  }

  async updateStatus(req, res, next) {
    try {
      const { ref_no } = req.params;
      const { status } = req.body;

      const validStatuses = ['draft', 'sent', 'approved', 'rejected', 'expired'];
      if (!validStatuses.includes(status)) {
        throw new AppError(`Invalid status. Must be one of: ${validStatuses.join(', ')}`, 400);
      }

      const [result] = await pool.query(
        'UPDATE quotations SET status = ? WHERE ref_no = ?',
        [status, ref_no]
      );

      if (result.affectedRows === 0) {
        throw new AppError('Quotation not found', 404);
      }

      const [quotes] = await pool.query(`
        SELECT q.*, u.username AS created_by_name
        FROM quotations q
        LEFT JOIN users u ON q.created_by = u.id
        WHERE q.ref_no = ?
      `, [ref_no]);

      res.json({ success: true, data: quotes[0], message: 'Status updated successfully' });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new QuoteController();