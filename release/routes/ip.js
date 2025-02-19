"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ip_utils_1 = require("../util/ip-utils");
const router = (0, express_1.Router)();
// Get IP address router
// Use a path parameter to retrieve the IP address to query. e.g.  http://server/ip/20.340.54.4
router.get("/:ip", (req, res) => {
    const ipAddress = req.params.ip;
    if ((0, ip_utils_1.TestIPv4Address)(ipAddress)) {
        res.json(ipAddress);
        if ((0, ip_utils_1.TestPrivateAddress)(ipAddress)) {
            res.status(404).json({ message: "IPv4 Address is a RFC1918 private address" });
            return;
        }
        res.send((0, ip_utils_1.TestIpInSubnet)(ipAddress, "10.0.0.0/24"));
    }
    else {
        res.status(404).json({ message: "IPv4 Address failed validation" });
    }
});
exports.default = router;
