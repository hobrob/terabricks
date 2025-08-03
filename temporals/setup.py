from setuptools import setup, find_packages
import os

meta = {}
with open(os.path.join("core", "__init__.py")) as f:
    exec(f.read(), meta)

setup(
  name='terabricks-temporals',
  version=meta['__version__'],
  author=meta['__author__'],
  url='https://github.com/hobrob/terabricks/tree/main/temporals',
  author_email='robert.price@rpdw.co.uk',
  description='A port of Teradata period types and associated operators to Databricks',
  packages=find_packages(include=['temporals', 'temporals.*'])
)
