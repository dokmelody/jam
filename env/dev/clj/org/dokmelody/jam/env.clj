(ns org.dokmelody.jam.env
  (:require
    [selmer.parser :as parser]
    [clojure.tools.logging :as log]
    [org.dokmelody.jam.dev-middleware :refer [wrap-dev]]))

(def defaults
  {:init
   (fn []
     (parser/cache-off!)
     (log/info "\n-=[dokmelody-jam started successfully using the development profile]=-"))
   :stop
   (fn []
     (log/info "\n-=[dokmelody-jam has shut down successfully]=-"))
   :middleware wrap-dev})
