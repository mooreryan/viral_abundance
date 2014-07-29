#! /usr/bin/env python

# Copyright 2013 Ryan Moore

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

from __future__ import print_function
import subprocess, sys, os

if len(sys.argv) < 2:
    sys.exit("Usage: %s /file/to/convert" % sys.argv[0])

if sys.argv[1] == "-h" or sys.argv[1] == "--help":
    sys.exit("Converts line endings to whatever is appropriate " +
             "for your OS\n\nUsage: %s /file/to/convert" % sys.argv[0])

if not os.path.exists(sys.argv[1]):
    sys.exit("Error: the file %s wasn't found!" % sys.argv[1])

tmp = '.tmp0R1y2A3nmoore481230948230948092348tmp2039482304.txt'
with open(tmp, 'w') as w:
    with open(sys.argv[1], 'U') as f:
        for line in f:
            print(line.rstrip(), file=w)

# get rid of tmp file
subprocess.call(["mv", tmp, sys.argv[1]])
