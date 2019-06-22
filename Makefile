lint:
	flake8 ./gshell.py

package:
	python setup.py check
	python setup.py sdist
	python setup.py bdist_wheel --universal

upload:
	twine upload dist/*

clean:
	rm -rf build
	rm -rf dist
