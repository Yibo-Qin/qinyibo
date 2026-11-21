#import "@local/modern-cug-report:0.1.3": *

#show: doc => template(
  doc,
  footer: "CUG水文气象学2026",
  header: "",
)

// 图表、公式按章编号；引用带“图/表”前缀
#set heading(numbering: "1.1")
#show figure: set figure(numbering: n => numbering("1.1", counter(heading).get().first(), n))
#show math.equation: set math.equation(numbering: (..n) => numbering("(1.1)", counter(heading).get().first(), n.pos().first()))
#show table.cell: set par(justify: false)
#show ref: it => {
  let el = it.element
  if el != none and el.func() == figure {
    link(el.location())[#el.supplement #numbering("1.1", counter(heading).at(el.location()).first(), ..counter(figure.where(kind: el.kind)).at(el.location()))]
  } else if el != none and el.func() == math.equation {
    link(el.location())[#numbering("(1.1)", counter(heading).at(el.location()).first(), ..counter(math.equation).at(el.location()))]
  } else {
    it
  }
}

#align(center)[
  #text(size: 1.4em, weight: "bold")[水文气象学 2026 · 第 1 章 编程基础]

  #text(size: 1em)[操作笔记 — 秦艺博（学号 046241）]
]

= 环境配置

== 已安装的工具

#figure(
  table(
    columns: (auto, auto, auto),
    align: (left, left, left),
    stroke: none,
    table.header([*工具*], [*版本*], [*用途*]),
    [git], [2.55.0], [版本管理],
    [gh], [2.105.0], [GitHub 命令行],
    [R], [4.6.1], [R 包开发],
    [typst], [0.15.1], [文档排版],
    [VSCode], [—], [编辑器 + Typst 插件],
  ),
  caption: [本地开发环境],
) <tab_env>

== GitHub 认证

由于本机网络无法直接访问 `github.com` 的 git 端口，采用 SSH over 443 方案：
把 `~/.ssh/config` 中的 `Host github.com` 指向 `ssh.github.com:443`，并添加公钥到
GitHub 账户。验证结果：

```bash
$ ssh -T git@github.com
Hi Yibo-Qin! You've successfully authenticated, but GitHub does not provide shell access.
```

`gh auth login` 使用设备码流程，登录后凭据保存在系统 keyring 中，
`gh auth status` 显示 `Logged in to github.com account Yibo-Qin`。

== git 身份

```bash
$ git config --global user.name  "Yibo Qin"
$ git config --global user.email "326482727+Yibo-Qin@users.noreply.github.com"
```

邮箱使用 GitHub 提供的 noreply 地址，避免真实邮箱泄露，且提交能正确关联到账户。

= R 包结构与代码组织

== 目录

基于 `https://github.com/rpkgs/rpkg.template` 模版创建仓库
`Yibo-Qin/qinyibo`，本地路径 `D:\qyb\qinyibo`。

#figure(
  table(
    columns: (auto, 1fr),
    align: (left, left),
    stroke: none,
    table.header([*路径*], [*内容*]),
    [`R/`], [只放函数，如 `Component.R`],
    [`man/`], [roxygen2 生成的帮助文档，不手改],
    [`tests/`], [testthat 测试代码],
    [`docs/`], [Typst 笔记，如本文],
    [`scripts/`], [一次性分析脚本，不打包],
    [`data-raw/`], [原始数据与整理脚本],
    [`DESCRIPTION`], [包名、版本、作者、依赖等元数据],
    [`NAMESPACE`], [导出函数声明，由 roxygen2 生成],
    [`.github/workflows/`], [R-CMD-check 自动化测试],
  ),
  caption: [项目目录与用途],
) <tab_dir>

其中 `R/` 与 `DESCRIPTION` 是 R 包的最小结构，其余为工程化的补充。

== 函数

`R/Component.R` 中实现了四个函数，均带 roxygen2 文档：

- `RemoveSeasonal()`：按给定的月日位置分组求均值，返回季节均值 `mu` 与去季节序列 `anomaly`；
- `lm_solve()`：用 `.lm.fit()` 求解最小二乘，返回系数、拟合值、残差与残差平方和；
- `LS_OneBreak()`：单断点分段回归（同斜率、异截距），断点两侧各一段；
- `LS_MultiBreaks()`：多断点分段回归，用哑变量构造设计矩阵。

单断点模型的矩阵形式为
$
  bold(Y) = bold(1) beta_0 + bold(X) beta_1 + bold(D)_(I_c) delta + bold(epsilon),
$ <eq_model>
其中 $bold(D)_(I_c)$ 在 $i > I_c$ 处取 1，因此 $delta$ 即断点后的截距变化量，
见式 @eq_model。

== 测试

`tests/testthat/test-Component.R` 共 6 个断言，覆盖：

+ `RemoveSeasonal()` 能正确减去分组均值，并处理缺失值；
+ `LS_OneBreak()` 在已知截距突变 $delta = 10$ 的数据上能还原该值；
+ `LS_MultiBreaks()` 在单断点时与 `LS_OneBreak()` 的残差平方和一致。

```bash
$ Rscript -e 'testthat::test_local()'
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 6 ]
```

= 持续集成

仓库的 `.github/workflows/R-CMD-check.yaml` 在每次 `git push` 后自动在
Ubuntu / Windows / macOS 上执行 `R CMD check`。本次提交结果为
`R-CMD-check success`，提交 `54e8eed` 旁可见绿色对勾。

模版自带的 `pkgdown.yaml`（需 GitHub Pages）与 `test-coverage.yaml`
（需 codecov token）在本地无法满足依赖，已删除，只保留必需的工作流。

= 遇到的问题

#figure(
  table(
    columns: (0.9fr, 1.5fr, 1.45fr),
    align: (left, left, left),
    stroke: none,
    table.header([*问题*], [*现象*], [*处理*]),
    [GitHub 直连被重置], [`scoop install`/`git clone` 均报连接被重置],
    [用 `ghfast.top` 镜像下载；git 改走 `ssh.github.com:443`],
    [新装程序找不到], [新终端仍提示“无法将 gh 项识别”],
    [PATH 未刷新，复制到已有的 `~/.local/bin`],
    [包名未改], [Actions 报 `library(rpkg.template)` 失败],
    [`README.md`、`tests/testthat.R` 里的包名改为 `qinyibo`],
    [R 包缺失], [无法加载 `roxygen2`、`testthat`],
    [改用清华 CRAN 镜像安装],
  ),
  caption: [踩坑记录与解决],
) <tab_issue>

= 小结

本章的关键不是写多少代码，而是建立可复现的工程习惯：
函数与脚本分离、文档由代码注释生成、测试随提交自动运行。
如 @tab_dir 所示的分层结构与经常使用的提示词
（“遵循 Linux 极简主义，一次做好一件事”）
能显著提高代码质量与协作效率。
