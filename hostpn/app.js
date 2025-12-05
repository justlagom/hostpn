const { spawn } = require("child_process");

// Binary and config definitions
const apps = [
  // 1. Xray 核心服务配置
  {
    name: "xy",
    // Xray 可执行文件路径
    binaryPath: "/home/container/xy/xy",
    // 规范化启动参数：使用 'run -config' 
    args: ["run", "-config", "/home/container/xy/config.json"] 
  },
  // 2. Caddy 静态网页伪装服务配置 (新增)
  {
    name: "caddy",
    // Caddy 可执行文件路径
    binaryPath: "/home/container/xy/caddy", 
    // 启动参数：使用 'run' 命令让其在前台运行，以便被守护
    args: ["run", "--config", "/home/container/xy/Caddyfile", "--adapter", "caddyfile"]
  }
];

/**
 * 运行指定的应用进程，并在其退出时自动重启（进程守护）。
 * @param {object} app - 包含 name, binaryPath, args 的应用配置对象。
 */
function runProcess(app) {
  // 使用 spawn 启动子进程，并将子进程的标准输出/错误输出连接到主进程
  const child = spawn(app.binaryPath, app.args, { stdio: "inherit" });

  console.log(`[START] Started process: ${app.name} (PID: ${child.pid})`);

  // 监听子进程的退出事件
  child.on("exit", (code) => {
    // 退出代码为 null 通常意味着子进程被信号杀死
    const exitCode = code === null ? 'Signal' : code; 
    console.log(`[EXIT] ${app.name} exited with code: ${exitCode}`);
    
    // 对于服务，通常选择重启以保证服务持续运行
    console.log(`[RESTART] Restarting ${app.name} in 3 seconds...`);
    setTimeout(() => runProcess(app), 3000); // 3秒后重启
  });

  // 监听子进程错误事件
  child.on("error", (err) => {
    console.error(`[ERROR] Failed to start ${app.name}:`, err);
  });
}

// Main execution
function main() {
  try {
    // 遍历 apps 数组，启动所有配置的服务
    for (const app of apps) {
      runProcess(app);
    }
  } catch (err) {
    console.error("[FATAL ERROR] Startup failed:", err);
    process.exit(1);
  }
}

main();
