import os
import re
import sys
import json
import shutil
import subprocess
from bs4 import BeautifulSoup
from markdownify import markdownify as md

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
EDGE_BIN = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
CAMPUS_IP = "10.249.12.224"
HOST_HEADER = "arch.p.cs-lab.top"

try:
    import pymupdf as fitz
except ImportError:
    try:
        import fitz
    except ImportError:
        fitz = None

def generate_pdf(url, out_path):
    if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
        return True
    cmd = [
        EDGE_BIN,
        "--headless=new",
        "--disable-gpu",
        "--run-all-compositor-stages-before-draw",
        f"--print-to-pdf={out_path}",
        "--no-pdf-header-footer",
        url
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 0

def fetch_url(url):
    cmd = [
        "curl.exe", "-s",
        "--connect-to", f"{HOST_HEADER}:443:{CAMPUS_IP}:443",
        url
    ]
    res = subprocess.run(cmd, capture_output=True)
    if res.returncode != 0:
        return None
    return res.stdout.decode("utf-8", errors="ignore")

def fetch_binary(url, out_path):
    cmd = [
        "curl.exe", "-s",
        "--connect-to", f"{HOST_HEADER}:443:{CAMPUS_IP}:443",
        "-o", out_path,
        url
    ]
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return os.path.exists(out_path) and os.path.getsize(out_path) > 0

def detect_lang(code_text):
    text = code_text.strip()
    if text.startswith(('sudo ', 'git ', 'cmake ', 'make ', 'gcc ', 'gdb ', 'cd ', 'mkdir ', 'curl ', 'chmod ', 'export ', 'cat ', 'ls ', './', '$ ')):
        return 'bash'
    if any(k in text for k in ['#include <', 'int main(', 'void ', 'uint64_t', 'printf(', 'return 0;', 'size_t ', 'double ', 'float ', 'char ']):
        return 'c'
    if any(k in text for k in ['vmovups', 'vfmadd', 'addsd', 'mulsd', 'movq', 'subq', 'pushq', 'popq', '.globl', '.type', '.text', 'movl', 'addl']):
        return 'x86asm'
    if '---' in text and '+++' in text and '@@' in text:
        return 'diff'
    if any(k in text for k in ['cmake_minimum_required', 'add_executable', 'target_link_libraries']):
        return 'cmake'
    return ''

def convert_html_to_md(html, page_url, lab_name):
    soup = BeautifulSoup(html, 'html.parser')
    article = soup.find('article', class_='md-content__inner')
    if not article:
        return '', ''

    # Extract H1 Title
    h1 = article.find('h1')
    title = h1.get_text().strip() if h1 else '章节'

    # Remove headerlinks
    for a in article.find_all('a', class_='headerlink'):
        a.decompose()

    # Strip decorative twemoji icons
    for img in article.find_all('img', class_='twemoji'):
        img.decompose()

    # Protect code blocks
    code_placeholders = {}
    code_idx = 0
    for hl in article.find_all('table', class_='highlighttable'):
        code_td = hl.find('td', class_='code')
        if code_td:
            code_elem = code_td.find('code')
            code_text = (code_elem or code_td).get_text().rstrip('\r\n')
            lang = detect_lang(code_text)
            block = f'```{lang}\n{code_text}\n```'
            pid = f'CODEBLOCKPLACEHOLDER{code_idx}'
            code_idx += 1
            code_placeholders[pid] = block
            hl.replace_with(soup.new_string(f'\n\n{pid}\n\n'))

    for hl in article.find_all('div', class_='highlight'):
        pre = hl.find('pre')
        if pre:
            code = pre.find('code') or pre
            code_text = code.get_text().rstrip('\r\n')
            lang = detect_lang(code_text)
            block = f'```{lang}\n{code_text}\n```'
            pid = f'CODEBLOCKPLACEHOLDER{code_idx}'
            code_idx += 1
            code_placeholders[pid] = block
            hl.replace_with(soup.new_string(f'\n\n{pid}\n\n'))

    # Admonitions
    admonition_map = {
        'warning': 'WARNING',
        'danger': 'CAUTION',
        'tip': 'TIP',
        'important': 'IMPORTANT',
        'info': 'NOTE',
        'note': 'NOTE',
        'example': 'NOTE',
    }
    admonition_placeholders = {}
    adm_idx = 0
    for adm in article.find_all('div', class_='admonition'):
        classes = adm.get('class', [])
        adm_type = 'NOTE'
        for c in classes:
            if c in admonition_map:
                adm_type = admonition_map[c]
                break

        title_elem = adm.find(class_='admonition-title')
        title_text = title_elem.get_text().strip() if title_elem else ''
        if title_elem:
            title_elem.decompose()

        for sub_hl in adm.find_all('table', class_='highlighttable'):
            c_td = sub_hl.find('td', class_='code')
            if c_td:
                c_text = c_td.get_text().rstrip('\r\n')
                l = detect_lang(c_text)
                sub_pre = soup.new_tag('pre')
                sub_code = soup.new_tag('code')
                sub_code.string = f'```{l}\n{c_text}\n```'
                sub_pre.append(sub_code)
                sub_hl.replace_with(sub_pre)

        inner_md = md(str(adm), heading_style='ATX').strip()
        alert_header = f'> [!{adm_type}] **{title_text}**' if title_text else f'> [!{adm_type}]'
        lines = [alert_header, '>']
        for line in inner_md.split('\n'):
            line = line.strip('\r')
            lines.append(f'> {line}' if line else '>')
        rendered_adm = '\n'.join(lines)
        pid = f'ADMONITIONPLACEHOLDER{adm_idx}'
        adm_idx += 1
        admonition_placeholders[pid] = rendered_adm
        adm.replace_with(soup.new_string(f'\n\n{pid}\n\n'))

    # Fix image links
    for img in article.find_all('img'):
        src = img.get('src', '')
        if src:
            fname = src.split('?')[0].split('/')[-1]
            if 'homewk.assets' in src or 'homewk' in page_url:
                img['src'] = f'./homewk.assets/{fname}'
            elif 'timetbl.png' in src:
                img['src'] = f'./assets/{fname}'
            else:
                img['src'] = f'./assets/{fname}'

    # Convert to Markdown
    res_md = md(str(article), heading_style='ATX', bullets='-')

    # Restore placeholders
    for pid, block in code_placeholders.items():
        res_md = res_md.replace(pid, block)
    for pid, block in admonition_placeholders.items():
        res_md = res_md.replace(pid, block)

    res_md = re.sub(r'\n{3,}', '\n\n', res_md).strip() + '\n'
    return title, res_md

def sync_all():
    print("=" * 60)
    print("开始全量同步与拉取计算机体系结构实验指导书...")
    print("=" * 60)
    
    # 1. 获取网站索引
    index_json_url = f"https://{HOST_HEADER}/search/search_index.json"
    index_raw = fetch_url(index_json_url)
    if not index_raw:
        print("无法获取 search_index.json，检查校园网连接。")
        return

    index_data = json.loads(index_raw)
    docs = index_data.get("docs", [])
    
    # 获取所有基础路径
    pages = sorted(list({d.get("location", "").split("#")[0] for d in docs}))
    print(f"成功获取站点页面列表，共发现 {len(pages)} 个页面路径。")

    # 按分类分组
    grouped = {} # group_name -> list of (location, sub_path)
    for loc in pages:
        if not loc:
            grouped.setdefault("root", []).append(("", "overview"))
        elif loc.startswith("homewk"):
            grouped.setdefault("root", []).append((loc, "homewk"))
        elif loc.startswith("lab"):
            parts = loc.strip("/").split("/")
            lab_key = parts[0] # e.g. lab1, lab2, lab3, lab4 ...
            sub = parts[1] if len(parts) > 1 else "overview"
            grouped.setdefault(lab_key, []).append((loc, sub))
        else:
            grouped.setdefault("other", []).append((loc, loc))

    # 规范排序子章节
    sub_order = ["overview", "theory", "step", "step1", "step2", "step3", "step4", "step5", "report", "preview"]
    def sub_sort_key(item):
        sub = item[1]
        return sub_order.index(sub) if sub in sub_order else 99

    for k in grouped:
        if k.startswith("lab"):
            grouped[k].sort(key=sub_sort_key)

    # 遍历同步
    all_labs_summary = []

    for group_key, items in sorted(grouped.items()):
        if group_key == "root":
            target_dir = BASE_DIR
            os.makedirs(os.path.join(target_dir, "assets"), exist_ok=True)
            os.makedirs(os.path.join(target_dir, "homewk.assets"), exist_ok=True)
        elif group_key.startswith("lab"):
            lab_num = group_key.replace("lab", "")
            target_dir = os.path.join(BASE_DIR, f"实验{lab_num}")
            os.makedirs(target_dir, exist_ok=True)
            os.makedirs(os.path.join(target_dir, "assets"), exist_ok=True)
        else:
            target_dir = os.path.join(BASE_DIR, group_key)
            os.makedirs(target_dir, exist_ok=True)

        print(f"\n正在同步模块: [{group_key}] -> {target_dir}")

        section_entries = []
        for loc_idx, (loc, sub) in enumerate(items):
            page_url = f"https://{HOST_HEADER}/{loc}"
            html = fetch_url(page_url)
            if not html:
                print(f"  获取失败: {page_url}")
                continue

            # 下载页面中的图片
            soup = BeautifulSoup(html, 'html.parser')
            article = soup.find('article', class_='md-content__inner')
            if article:
                for img_tag in article.find_all('img'):
                    src = img_tag.get('src')
                    if src and not src.startswith('data:'):
                        img_name = src.split('?')[0].split('/')[-1]
                        if 'timetbl' in img_name:
                            dst = os.path.join(BASE_DIR, 'assets', img_name)
                            img_url = f"https://{HOST_HEADER}/timetbl.png"
                        elif 'homewk.assets' in src or 'homewk' in loc:
                            dst = os.path.join(BASE_DIR, 'homewk.assets', img_name)
                            img_url = f"https://{HOST_HEADER}/homewk.assets/{img_name}"
                        else:
                            dst = os.path.join(target_dir, 'assets', img_name)
                            img_url = f"https://{HOST_HEADER}/{group_key}/assets/{img_name}"
                        
                        if not os.path.exists(dst):
                            fetch_binary(img_url, dst)

            # 确定文件名
            if group_key == "root":
                fname = "00_课程概况.md" if sub == "overview" else "01_作业提交说明.md"
            else:
                name_map = {
                    "overview": "00_实验概述.md",
                    "theory": "01_实验原理.md",
                    "step": "02_实验步骤.md",
                    "step1": "02_练习1.md",
                    "step2": "03_练习2.md",
                    "step3": "04_练习3.md",
                    "step4": "05_练习4.md",
                    "step5": "06_练习5.md",
                    "report": "05_实验报告要求.md" if len(items) <= 7 else "07_实验报告要求.md",
                    "preview": f"{len(items)-1:02d}_预习下一个实验.md",
                }
                fname = name_map.get(sub, f"{loc_idx:02d}_{sub}.md")

            title, md_content = convert_html_to_md(html, page_url, group_key)
            out_file = os.path.join(target_dir, fname)
            with open(out_file, 'w', encoding='utf-8') as fp:
                fp.write(md_content)
            print(f"  [Markdown] {fname} ({title})")
            section_entries.append((fname, title, md_content, page_url, sub))

            # 导出对应的 PDF（如果不存在）
            if group_key.startswith("lab"):
                lab_num = group_key.replace("lab", "")
                pdf_name_map = {
                    "overview": f"实验{lab_num}_实验概述.pdf",
                    "theory": f"实验{lab_num}_实验原理.pdf",
                    "step": f"实验{lab_num}_实验步骤.pdf",
                    "step1": f"实验{lab_num}_实验步骤_练习1.pdf",
                    "step2": f"实验{lab_num}_实验步骤_练习2.pdf",
                    "step3": f"实验{lab_num}_实验步骤_练习3.pdf",
                    "step4": f"实验{lab_num}_实验步骤_练习4.pdf",
                    "step5": f"实验{lab_num}_实验步骤_练习5.pdf",
                    "report": f"实验{lab_num}_实验报告要求.pdf",
                    "preview": f"实验{lab_num}_预习下一个实验.pdf",
                }
                pdf_fname = pdf_name_map.get(sub, f"实验{lab_num}_{sub}.pdf")
                pdf_out = os.path.join(target_dir, pdf_fname)
                if not os.path.exists(pdf_out):
                    # Check legacy hyphen format
                    legacy_names = [
                        pdf_fname.replace("_", "-"),
                        f"实验{lab_num}-概述.pdf" if sub == "overview" else "",
                        f"实验{lab_num}-实验步骤{sub.replace('step', '')}.pdf" if sub.startswith("step") else "",
                    ]
                    found = False
                    for leg in legacy_names:
                        if leg and os.path.exists(os.path.join(target_dir, leg)):
                            pdf_out = os.path.join(target_dir, leg)
                            found = True
                            break
                    if not found:
                        print(f"  [PDF] 正在导出 {pdf_fname} ...")
                        generate_pdf(page_url, pdf_out)

        # 生成该 Lab 的完整汇总 Markdown 与 PDF
        if group_key.startswith("lab"):
            lab_num = group_key.replace("lab", "")
            sum_md_name = f"实验{lab_num}指导书汇总.md"
            sum_md_path = os.path.join(target_dir, sum_md_name)
            
            lines = [
                f"# 计算机体系结构实验 - 实验{lab_num}指导书汇总",
                "",
                f"> 本文档为实验{lab_num}所有章节的 1:1 完整汇总转译版，供离线阅读与后续 Agent 查阅。",
                "",
                "## 目录导航",
                ""
            ]
            for fn, tit, _, _, _ in section_entries:
                lines.append(f"- [{tit}](./{fn})")
            lines.append("\n---\n")

            for fn, tit, cnt, _, _ in section_entries:
                lines.append(f"<!-- Section: {fn} -->")
                lines.append(cnt)
                lines.append("\n---\n")

            with open(sum_md_path, 'w', encoding='utf-8') as fp:
                fp.write("\n".join(lines))
            print(f"  [汇总版] {sum_md_name}")

            sum_pdf_name = f"实验{lab_num}指导书汇总.pdf"
            sum_pdf_path = os.path.join(target_dir, sum_pdf_name)
            if not os.path.exists(sum_pdf_path) and fitz:
                part_pdfs = [os.path.join(target_dir, pdf_name_map.get(s, f"实验{lab_num}_{s}.pdf")) for _, _, _, _, s in section_entries]
                doc = fitz.open()
                for p in part_pdfs:
                    if os.path.exists(p):
                        sub_doc = fitz.open(p)
                        doc.insert_pdf(sub_doc)
                        sub_doc.close()
                doc.save(sum_pdf_path)
                doc.close()
                print(f"  [汇总PDF] {sum_pdf_name}")

            all_labs_summary.append((lab_num, target_dir, section_entries))

    # 更新根目录 README.md
    print("\n正在更新根目录 README.md 索引...")
    readme_lines = [
        "# 哈工大（深圳）计算机体系结构实验指导书（2026秋季）",
        "",
        "本目录包含完整的课程实验指导书，分为 **PDF 离线版** 与 **Markdown 1:1 结构化转译版**，并已下载所有插图与实验素材，支持完全离线查看。",
        "",
        "---",
        "",
        "## 目录结构导航",
        "",
        "### 0. 课程总体说明",
        "- [00_课程概况.md](./00_课程概况.md) （对应 PDF: [课程概况.pdf](./课程概况.pdf)）",
        "- [01_作业提交说明.md](./01_作业提交说明.md) （对应 PDF: [作业提交说明.pdf](./作业提交说明.pdf)）",
        "- 参考资料: [x86-64-reference.pdf](./x86-64-reference.pdf)",
        ""
    ]

    for lab_num, ldir, sections in all_labs_summary:
        readme_lines.append(f"### {lab_num}. 实验{lab_num}")
        readme_lines.append("- **章节指导书**：")
        for fn, tit, _, _, _ in sections:
            readme_lines.append(f"  - [{fn}](./实验{lab_num}/{fn}) （{tit}）")
        readme_lines.append(f"- **完整汇总版**：[实验{lab_num}指导书汇总.md](./实验{lab_num}/实验{lab_num}指导书汇总.md)")
        readme_lines.append("")

    readme_lines.extend([
        "---",
        "",
        "## Agent 使用提示",
        "- 每一份 Markdown 文档均包含 1:1 无损转译的理论知识、操作步骤、代码命令、参数配置及思考题说明。",
        "- 所有实验涉及的配图位于同级目录下的 `assets/` 文件夹中，支持离线预览。",
        "- 后续开发和调试任务时，Agent 可根据任务目标精确加载对应的 `0x_练习x.md` 文件，减少上下文负载。",
        "- **更新与增量同步**：若网站更新了新实验，可运行 `python docs/sync_docs.py` 全自动拉取解析并生成对应文档。",
        ""
    ])

    with open(os.path.join(BASE_DIR, "README.md"), "w", encoding="utf-8") as fp:
        fp.write("\n".join(readme_lines))

    print("\n全量同步与更新完成。")

if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sync_all()
