const { spawn } = require("child_process");

// Binary and config definitions
const apps = [
  {
    name: "xy",
    binaryPath: "/home/container/xy/xy",
    args: ["-c", "/home/container/xy/config.json"]
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
    
    // 检查是否是正常退出 (例如，如果是 0，可以选择不重启，但对于服务通常选择重启)
    // if (code !== 0) {
      console.log(`[RESTART] Restarting ${app.name} in 3 seconds...`);
      setTimeout(() => runProcess(app), 3000); // 3秒后重启
    // }
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
