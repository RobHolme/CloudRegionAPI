import express, { Request, Response } from "express";
import ipRoutes from "./routes/ip";

// create a new express application instance
const app = express();
const PORT = process.env.PORT || 80;
app.use(express.json());

// define the routes
app.use("/ip", ipRoutes);

// handle requests for the root URL
app.get("/", (req: Request, res: Response) => {
  res.send("Welcome");
});

// handle requests for the /info URL
app.get("/info", (req: Request, res: Response) => {
res.setHeader('content-type', 'application/json');
var jsonResult: Object = {
    ClientIP: req.ip,
    Protocol: req.protocol,
    HTTPVersion: req.httpVersion,
    Headers: req.headers
};
res.send(JSON.stringify(jsonResult, null, 2));
});

// start the Express server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});