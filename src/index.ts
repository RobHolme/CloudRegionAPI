import fs from 'fs';
import express, { NextFunction, Request, Response } from "express";
import hostnameRoute from "./routes/hostname";
import infoRoute from "./routes/info";
import allsubnetsRoute from "./routes/allsubnets";
import httpCompression from 'compression';

// create a new express application instance
const app = express();
const PORT = process.env.PORT || 80;


// middleware to block specific HTTP methods that are not required.
const blockMethodsMiddleware = (req: Request, res: Response, next: NextFunction): void => {
  const blockedMethods: string[] = ['POST', 'PUT', 'DELETE', 'PATCH', 'TRACE', 'CONNECT'];
  if (blockedMethods.includes(req.method)) {
  res.status(405).json({ message: `${req.method} method is not allowed.`});
    return;
  }
  next();
};
app.use(blockMethodsMiddleware);


app.use(express.json());
// disable the 'x-powered-by' header in the response
app.disable('x-powered-by');
// enable http compression
app.use(httpCompression());
// define the routes foreach API
app.use("/api/hostname", hostnameRoute);
app.use("/api/info", infoRoute);
app.use("/api/subnets", allsubnetsRoute);

// static URL for favicon, css and script files
app.use('/favicon.ico', express.static('./release/images/favicon.ico'));
app.use('/styles.css', express.static('./release/html/styles.css'));
app.use('/scripts.js', express.static('./release/html/scripts.js'));


// handle requests for the root URL
app.get("/", (req: Request, res: Response) => {
  // apply security headers
  res.setHeader('Content-Security-Policy', "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self'; style-src 'self'; frame-ancestors 'none'; form-action 'self';");
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('Referrer-Policy', 'strict-origin-when-cross-origin');
  
  var html: string = fs.readFileSync('./release/html/search.html', 'utf-8');
  res.send(html);
});

// start the Express server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});