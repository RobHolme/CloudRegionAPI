import { Router, Request, Response } from "express";
import fs from 'fs';

const router = Router();

// -----------------------------
// info name router (/)
// No parameters. Return diagnostic information as a JSON object.
// -----------------------------
router.get("/", (req: Request, res: Response) => {
    res.setHeader('content-type', 'application/json');
    // read the build date generated during the container build.
    // use 'unknown' as build date if ./release/build_date.txt file is missing - i.e. when running from source instead of from a container)
    try {
        var buildDate: string = fs.readFileSync('./release/build_date.txt', 'utf-8');
    }
    catch {
        buildDate = "unknown";
    }

    // display diagnostic information
    var jsonResult: Object = {
        BuildDate: buildDate,
        ClientIP: req.ip,
        Protocol: req.protocol,
        HTTPVersion: req.httpVersion,
        Headers: req.headers
    };
    res.send(JSON.stringify(jsonResult, null, 2));
});

export default router;