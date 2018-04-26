// Copyright (c) 2017, racruz. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

library secdart;

export 'src/default_lattice.dart';

/**
 * Downgrades the security label of the given expression.
 *
 * It behaves as an identity function, however the security analysis recognizes
 * it and perform the necessary downgrade.
 */
T declassify<T>(T expression, label) => expression;

/**
 * Represents a label annotation. Its interpretation is open.
 * eg. Lab("H"), Lab("Alice -> Bob")
 */
class lab {
  final String labelRep;
  const lab(String this.labelRep);
}

/**
 * Label for function annotations
 */
class latent {
  /**
   * The label required to invoke the function
   */
  final String beginLabel;

  /**
   * The label of the return value of the function can not be higher than the [endlabel]
   */
  final String endLabel;
  const latent(this.beginLabel, this.endLabel);
}
