(ns dok-jam.env
  (:require [clojure.tools.logging :as log]))

(def defaults
  {:init
   (fn []
     (log/info "\n-=[dok-jam started successfully]=-"))
   :stop
   (fn []
     (log/info "\n-=[dok-jam has shut down successfully]=-"))
   :middleware identity})
