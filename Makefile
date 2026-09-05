.PHONY: pdf clean test-pdf

BOOK_NAME = 国产FDE修炼之道

CHAPTERS = \
	assets/cover.md \
	前线，不是前端.md \
	一个被嘲笑了二十年的模式.md \
	同名，不同命.md \
	三份JD，三种逻辑.md \
	林浩的一天.md \
	要干这些，我需要什么技能.md \
	踩坑录.md \
	适不适合你.md \
	90天入行路线图.md \
	出路.md \
	资源地图.md \
	国内JD数据库.md \
	术语表.md

pdf:
	mkdir -p dist
	pandoc $(CHAPTERS) \
		--metadata-file=metadata.yaml \
		--pdf-engine=xelatex \
		--toc \
		--toc-depth=2 \
		--number-sections \
		-V geometry:"margin=2.5cm, top=3cm, bottom=3cm" \
		-o "dist/$(BOOK_NAME).pdf"
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
