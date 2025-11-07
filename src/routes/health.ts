import { Router, Request, Response } from "express";
const router = Router();

// -----------------------------
// Health check URL for Docker health check
// -----------------------------
router.get('/health', (req, res) => {
    res.status(200).json({ message: 'healthy' });
});

export default router;