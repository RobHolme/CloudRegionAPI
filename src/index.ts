import express, { Request, Response } from "express";
import ipRoutes from "./routes/ip";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use("/ip", ipRoutes);

app.get("/", (req: Request, res: Response) => {
  res.send("Welcome");
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});