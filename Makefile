.PHONY: pdf clean test-pdf

BOOK_NAME = 国产FDE修炼之道

CHAPTERS = \
	assets/cover.md \
	part1-cognition/01-what-is-fde.md \
	part1-cognition/02-market-background.md \
	part1-cognition/03-china-vs-silicon-valley.md \
	part2-china-battle/04-domestic-jd-analysis.md \
	part2-china-battle/05-real-day-in-china.md \
	part2-china-battle/06-china-skill-tree.md \
	part2-china-battle/07-lessons-from-the-field.md \
	part3-decision-action/08-is-this-for-me.md \
	part3-decision-action/09-90-day-roadmap.md \
	part3-decision-action/10-career-outlook.md \
	appendix/resources.md \
	appendix/jd-database.md \
	appendix/glossary.md

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
