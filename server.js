import express from "express";
const app = express();
app.use(express.json());

app.get("/*url", (req, res)=> {
    const fetching_url = req.url.replace("/", "");
    console.log(fetching_url);
    return res.status(200).json(
        {
            success: true,
            url: fetching_url
        }
    );
});

app.listen(3939, ()=> {
    console.log("Server is running on port 3939");  
});