from distutils.core import setup

def readme():
    with open('README.rst') as f:
        return f.read()

setup(
    name = "telnetsrv3",
    packages = ["telnetsrv"],
    version = "0.5",
    extras_require = {
        'green': ['gevent'],
        'ssh': ['paramiko'],
        },
    description = "Telnet server handler library",
    long_description = readme(),
    author = "Ian Epperson",
    author_email = "ian@epperson.com",
    url = "https://github.com/Blindfreddy/telnetsrvlib3",
    keywords = ["gevent", "telnet", "server"],
    classifiers = [
        "Programming Language :: Python",
        "Development Status :: 4 - Beta",
        "Environment :: Other Environment",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: GNU Library or Lesser General Public License (LGPL)",
        "Operating System :: OS Independent",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Communications",
        "Topic :: Communications :: BBS",
        "Topic :: System :: Shells",
        "Topic :: Terminals",
        "Topic :: Terminals :: Telnet",
        ],
)
