SWIPL := swipl
TEST_FILE := typeInf.plt

.PHONY: test

test:
	$(SWIPL) -q -g "consult('$(TEST_FILE)'), run_tests, halt."
