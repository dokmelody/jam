package org.dokmelody.jam;

import clojure.java.api.Clojure;
import clojure.lang.IFn;

import java.io.File;
import java.io.FileFilter;
import java.util.concurrent.Callable;

public class Test {
    public static void callClojure(String ns, String fn) throws Exception {
        // load Clojure lib. See https://clojure.github.io/clojure/javadoc/clojure/java/api/Clojure.html
        IFn require = Clojure.var("clojure.core", "require");
        require.invoke(Clojure.read(ns));

        Clojure.var(ns, fn).invoke();
    }
    public static void main(String[] args) throws Exception {
        callClojure("org.dokmelody.jam.test.core", "-test-all");
    }
}
