.PHONY: pdf clean test-pdf

BOOK_NAME = 国产FDE修炼之道

CHAPTERS = \
	01-前线，不是前端.md \
	02-一个被嘲笑了二十年的模式.md \
	03-同名，不同命.md \
	04-三份JD，三种逻辑.md \
	05-林浩的一天.md \
	06-要干这些，我需要什么技能.md \
	07-踩坑录.md \
	08-适不适合你.md \
	09-90天入行路线图.md \
	10-出路.md \
	附录A-资源地图.md \
	附录B-国内JD数据库.md \
	附录C-术语表.md

pdf:
	mkdir -p dist
	# 1. 构建内页 PDF
	pandoc $(CHAPTERS) \
		--metadata-file=metadata.yaml \
		--pdf-engine=xelatex \
		--toc \
		--toc-depth=2 \
		--number-sections \
		-V geometry:"margin=2.5cm, top=3cm, bottom=3cm" \
		-V tocdepth=1 \
		-o "dist/_body_tmp.pdf"
	# 2. 封面 PNG → PDF，再与内页合并
	python3 scripts/merge_pdf.py "$(BOOK_NAME).pdf"
	@echo "✅ PDF generated: dist/$(BOOK_NAME).pdf"

test-pdf:
	@echo "# 测试章节" > /tmp/test-fde.md
	@echo "这是中文测试：前线部署工程师 FDE。" >> /tmp/test-fde.md
	pandoc /tmp/test-fde.md \
		--pdf-engine=xelatex \
		-V CJKmainfont="Noto Serif CJK SC" \
		-o /tmp/test-fde.pdf
	@echo "✅ 中文渲染测试通过，查看 /tmp/test-fde.pdf"

clean:
	rm -rf dist/
