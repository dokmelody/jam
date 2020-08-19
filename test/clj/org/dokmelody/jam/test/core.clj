;; SPDX-License-Identifier: MIT
;; Copyright (C) 2020 Massimo Zaniboni <mzan@dokmelody.org>

(ns org.dokmelody.jam.test.core
  (:require [org.dokmelody.jam.test.doknil :as doknil]
            [org.dokmelody.jam.test.handler :as ring]
            [clojure.test :as test]))

(defn -test-all []
  (test/run-tests 'org.dokmelody.jam.test.doknil 'org.dokmelody.jam.test.handler))
