// Copyright (c) 2017, racruz. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library secdart;

export 'src/flat_lattice.dart';

/**
 * Downgrades the security label of the given expression.
 *
 * It behaves as an identity function, however the security analysis recognizes
 * it and perform the necessary downgrade.
 */
T declassify<T>(T expression, label) => expression;
