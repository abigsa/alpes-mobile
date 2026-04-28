const express = require('express');
const router = express.Router();
const { upload, cloudinary } = require('../config/cloudinary');
const { getConnection } = require('../config/db');
const { closeConn } = require('../utils/oracle');

// POST /api/upload/producto/:id
router.post('/producto/:id', upload.single('imagen'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ ok: false, mensaje: 'No se recibió ninguna imagen' });
    }

    const imageUrl = req.file.path;
    const productoId = req.params.id;

    const conn = await getConnection();
    try {
      await conn.execute(
        `UPDATE PRODUCTO SET IMAGEN_URL = :url WHERE PRODUCTO_ID = :id`,
        { url: imageUrl, id: productoId }
      );
      await conn.commit();
    } finally {
      await closeConn(conn);
    }

    res.json({ ok: true, url: imageUrl });
  } catch (error) {
    console.error('Error subiendo imagen:', error);
    res.status(500).json({ ok: false, mensaje: 'Error al subir imagen' });
  }
});

// DELETE /api/upload/producto/:id
router.delete('/producto/:id', async (req, res) => {
  const conn = await getConnection();
  try {
    const result = await conn.execute(
      `SELECT IMAGEN_URL FROM PRODUCTO WHERE PRODUCTO_ID = :id`,
      { id: req.params.id }
    );

    const url = result.rows[0]?.[0];
    if (url) {
      const parts = url.split('/');
      const file = parts[parts.length - 1];
      const publicId = `alpes-productos/${file.split('.')[0]}`;
      await cloudinary.uploader.destroy(publicId);
    }

    await conn.execute(
      `UPDATE PRODUCTO SET IMAGEN_URL = NULL WHERE PRODUCTO_ID = :id`,
      { id: req.params.id }
    );
    await conn.commit();

    res.json({ ok: true, mensaje: 'Imagen eliminada' });
  } catch (error) {
    console.error('Error eliminando imagen:', error);
    res.status(500).json({ ok: false, mensaje: 'Error al eliminar imagen' });
  } finally {
    await closeConn(conn);
  }
});

module.exports = router;