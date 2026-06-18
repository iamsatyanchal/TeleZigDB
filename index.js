import express from "express";
import fetch from "node-fetch";

const app = express();

app.use(express.json());

app.get("/", async (req, res) => {
    const fetching_url = req.query.url;

    if (!fetching_url) {
        return res.status(400).json({
            success: false,
            error: "Missing url parameter"
        });
    }
    console.log(fetching_url);
    
    try {
        const response = await fetch(fetching_url);

        const contentType = response.headers.get("content-type") || "";

        if (contentType.includes("application/json")) {
            const data = await response.json();

            return res.status(response.status).json(data);
        }

        const text = await response.text();

        return res.status(response.status).send(text);

    } catch (error) {
        console.error(error);

        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

app.listen(3000, () => {
    console.log("Server running on port 3000");
});