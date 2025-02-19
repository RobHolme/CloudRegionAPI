import { Router, Request, Response } from "express";
import { TestIPv4Address, TestIPv4Subnet, TestPrivateAddress, TestIpInSubnet } from '../util/ip-utils';

const router = Router();

// Get IP address router
// Use a path parameter to retrieve the IP address to query. e.g.  http://server/ip/20.340.54.4
router.get("/:ip", (req: Request, res: Response) => {
    const ipAddress = req.params.ip;
    if (TestIPv4Address(ipAddress)) {
      res.json(ipAddress);
      if (TestPrivateAddress(ipAddress)) {
        res.status(404).json({ message: "IPv4 Address is a RFC1918 private address" });
        return;
      }
    } else {
      res.status(404).json({ message: "IPv4 Address failed validation" });
    }
  });

  export default router;