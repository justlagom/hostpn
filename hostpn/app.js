const { spawn } = require("child_process");
const fs = require("fs");
const path = require("path");

// --- Configuration Variables ---
// 从环境变量中读取 NGINX 暴露端口，如果未设置则默认为 443
const NGINX_PORT = process.env.NGINX_PORT || "443";
// Xray 配置的 Path，必须与 Xray 配置中的 path 字段一致
const XHTTP_PATH = process.env.XHTTP_PATH || "/b3a053a4"; 
// Nginx 监听的内部回落端口（与 Xray 配置中的 Fallback 目标保持一致）
const XRAY_INBOUND_PORT = "8080"; 

// Nginx 配置文件的路径
const NGINX_CONF_PATH = "/home/container/xy/nginx.conf";
// Nginx 配置模板路径 (假设 install.sh 已经将其复制到 /home/container/xy/)
const NGINX_CONF_TEMPLATE_PATH = "/home/container/xy/nginx.conf.template";


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
        // Nginx 可执行文件路径 (请根据您的运行环境调整，这里使用常见的 /usr/sbin/nginx)
        binaryPath: "/usr/sbin/nginx", 
        // 启动参数：使用 -c 指定配置文件，并用 -g "daemon off;" 确保它在前台运行
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
        setTimeout(() => runProcess(app), 3000); // 3秒后重启
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

    // 将最终内容写入到 Nginx 配置文件路径
    fs.writeFileSync(NGINX_CONF_PATH, templateContent);

    console.log(`[CONFIG] Nginx configuration written to ${NGINX_CONF_PATH}.`);
}

// Main execution
function main() {
    try {
        // 1. 在启动服务前，先生成 Nginx 配置文件
        configureNginx();

        // 2. 遍历 apps 数组，启动所有配置的服务
        for (const app of apps) {
            runProcess(app);
        }
    } catch (err) {
        console.error("[FATAL ERROR] Startup failed:", err);
        process.exit(1);
    }
}

main();
