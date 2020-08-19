(ns org.dokmelody.jam.env
  (:require [clojure.tools.logging :as log]))

(def defaults
  {:init
   (fn []
     (log/info "\n-=[dokmelody-jam started successfully]=-"))
   :stop
   (fn []
     (log/info "\n-=[dokmelody-jam has shut down successfully]=-"))
   :middleware identity})
