const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

// --- Configuration Variables ---
// 从环境变量中读取 NGINX 暴露端口，如果未设置则默认为 443
const NGINX_PORT = process.env.NGINX_PORT || "443";
// Xray 配置的 Path
const XHTTP_PATH = process.env.XHTTP_PATH || "/b3a053a4"; 
// Nginx 监听的内部回落端口
const XRAY_INBOUND_PORT = "8080"; 

// ⚠️ 关键修改 1: Nginx 配置文件名和路径
const NGINX_CONF_PATH = "/home/container/xy/nginx.conf"; // 最终生成的 Nginx 配置
const NGINX_CONF_TEMPLATE_PATH = "/home/container/xy/nginx.conf"; // install.sh 复制到此处的模板


// Binary and config definitions
const apps = [
    // 1. Xray 核心服务配置
    {
        name: "xy",
        binaryPath: "/home/container/xy/xy",
        args: ["run", "-config", "/home/container/xy/config.json"] 
    },
    // 2. Nginx 反代和静态网页服务配置
    {
        name: "nginx",
        binaryPath: "/usr/sbin/nginx", 
        args: ["-c", NGINX_CONF_PATH, "-g", "daemon off;"]
    }
];

/**
 * 运行指定的应用进程，并在其退出时自动重启（进程守护）。
 */
function runProcess(app) {
    const child = spawn(app.binaryPath, app.args, { stdio: "inherit" });
    console.log(`[START] Started process: ${app.name} (PID: ${child.pid})`);

    child.on("exit", (code) => {
        const exitCode = code === null ? 'Signal' : code; 
        console.log(`[EXIT] ${app.name} exited with code: ${exitCode}`);
        
        console.log(`[RESTART] Restarting ${app.name} in 3 seconds...`);
        setTimeout(() => runProcess(app), 3000); 
    });

    child.on("error", (err) => {
        console.error(`[ERROR] Failed to start ${app.name}:`, err);
    });
}

/**
 * 根据环境变量和模板生成 Nginx 配置文件。
 */
function configureNginx() {
    console.log(`[CONFIG] Generating Nginx configuration: External Port ${NGINX_PORT}, Xray Port ${XRAY_INBOUND_PORT}, Path ${XHTTP_PATH}.`);

    if (!fs.existsSync(NGINX_CONF_TEMPLATE_PATH)) {
        throw new Error(`Nginx template not found at: ${NGINX_CONF_TEMPLATE_PATH}. Please check install.sh.`);
    }

    // 读取模板内容
    let templateContent = fs.readFileSync(NGINX_CONF_TEMPLATE_PATH, 'utf8');

    // 替换 Nginx 监听端口和 Xray 回落端口的占位符
    templateContent = templateContent.replace(/NGINX_PORT_PLACEHOLDER/g, NGINX_PORT);
    templateContent = templateContent.replace(/XRAY_INBOUND_PORT_PLACEHOLDER/g, XRAY_INBOUND_PORT);
    templateContent = templateContent.replace(/XHTTP_PATH_PLACEHOLDER/g, XHTTP_PATH);

    // ⚠️ 关键修改 2: 写入最终配置文件 (模板名和最终名一致)
    fs.writeFileSync(NGINX_CONF_PATH, templateContent);

    console.log(`[CONFIG] Nginx configuration written to ${NGINX_CONF_PATH}.`);
}

// Main execution
function main() {
    try {
        configureNginx();
        for (const app of apps) {
            runProcess(app);
        }
    } catch (err) {
        console.error("[FATAL ERROR] Startup failed:", err);
        process.exit(1);
    }
}

main();
