import { Router, Request, Response } from "express";
const router = Router();

// -----------------------------
// Health check URL for Docker health check
// -----------------------------
router.get('/', (req, res) => {
    res.setHeader('content-type', 'application/json');
    res.status(200).json({ message: 'healthy' });
});

export default router;