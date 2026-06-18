import express from "express";
import fetch from "node-fetch";
const app = express();
app.use(express.json());

app.get("/*url", async (req, res)=> {
    const fetching_url = req.url.replace("/", "");
    var original_data;
    console.log(fetching_url);

    // try {
    //     original_data = await fetch(fetching_url.slice(1)).then(response => response.json());
    // } catch (error) {
    //     console.log(error);
    //     return res.status(500).json(
    //         {
    //             success: false,
    //         });
    // }
    return res.status(200).json(
        {
            success: true,
            url: fetching_url,
            // data: original_data
        }
    );
});

app.listen(3000, ()=> {
    console.log("Server is running on port 3939");  
});