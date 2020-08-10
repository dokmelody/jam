(ns dok-jam.env
  (:require
    [selmer.parser :as parser]
    [clojure.tools.logging :as log]
    [dok-jam.dev-middleware :refer [wrap-dev]]))

(def defaults
  {:init
   (fn []
     (parser/cache-off!)
     (log/info "\n-=[dok-jam started successfully using the development profile]=-"))
   :stop
   (fn []
     (log/info "\n-=[dok-jam has shut down successfully]=-"))
   :middleware wrap-dev})
