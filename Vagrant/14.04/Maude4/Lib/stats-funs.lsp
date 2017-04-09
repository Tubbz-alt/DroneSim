
;; (supdate "g2d.util.ActorMsg" "VERBOSE" (boolean true))
;; (supdate "g2d.Main" "DEBUG" (boolean true))


(define makeInteger (int_or_string)
  (sinvoke "java.lang.Integer" "valueOf" int_or_string))

(define makeDouble (double_or_string)
  (sinvoke "java.lang.Double" "valueOf" double_or_string))


(define doRun (handle)
  (sinvoke "g2d.util.ActorMsg"  "send" "maude" handle "doRun")
  )

;; replies with  (apply runResult "handle" val)


(define runResult (handle val)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
		 (seq
     	;; (invoke statsObject "recordRunResult" (apply makeDouble val))
      (invoke statsObject "recordRunResult" val)
      (invoke java.lang.System.err "println" (concat "runResult: " val))
      (sinvoke "g2d.util.ActorMsg"  "send" "maude" "g2d" "OK")
      (apply doStatsAux handle statsObject (invoke statsObject "done"))
      )) ))


(define doStats (handle)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
	(apply doStatsAux handle statsObject (boolean false)))
    )
  )

(define doStatsAux (handle statsObject isDone)
  (if isDone
      (invoke java.lang.System.err "println" statsObject)
    (seq
     (invoke java.lang.System.err "println" (concat "calling doRun"))
     (apply doRun handle)
     )) )


(define doConcurrentStats (handle maudes)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
	(for maude maudes
	     (apply doConcurrentStatsAux handle maude statsObject (boolean false)))
      )
    )
  )

(define doConcurrentStatsAux (handle maude statsObject isDone)
  (if isDone
      (invoke java.lang.System.err "println" statsObject)
    (seq
     (invoke java.lang.System.err "println" (concat "calling doRun with " maude))
     (apply doConcurrentRun handle maude)
     )) )


(define doConcurrentRun (handle maude)
  (sinvoke "g2d.util.ActorMsg"  "send" maude handle "doRun")
  )

(define runConcurrentResult (handle maude val)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
	(seq
	 ;; (invoke statsObject "recordRunResult" (apply makeDouble val))
	 (invoke statsObject "recordRunResult" val)
	 (invoke java.lang.System.err "println" (concat "runResult from " maude " : " val ))
	 (sinvoke "g2d.util.ActorMsg"  "send" maude "g2d" "OK")
	 (apply doConcurrentStatsAux handle maude statsObject (invoke statsObject "done"))
	 )) ))


(define maude2plambda (maude)
  (concat "plambda" (invoke maude "substring" (invoke "maude" "length"))))


(define doConcurrentStatsGracefully (handle maudes drone_count)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
	(for maude maudes
	     (apply doConcurrentStatsGracefullyAux handle maude  drone_count statsObject (boolean false)))
      )
    )
  )

(define doConcurrentStatsGracefullyAux (handle maude drone_count statsObject isDone)
  (if isDone
      ;; at this point we can shutdown all the drones in the plambda that is twinned with the
      ;; maude.
      (let ((plambda (apply maude2plambda maude)))
	(invoke java.lang.System.err "println" (concat "isDone is true shutting down the drones in " plambda))
	(invoke java.lang.System.err "println" statsObject)
	(for droneid drone_count
	     (invoke java.lang.System.err "println" (concat "Shutting down drone: " (concat "b" droneid)))
	     (sinvoke "g2d.util.ActorMsg"  "send" plambda maude (concat "(invoke " (concat "b" droneid) " \"shutdown\")"))
	     )
	)
    (seq
     (invoke java.lang.System.err "println" (concat "calling doRun with " maude))
     (apply doConcurrentRunGracefully handle maude)
     )) )

;;;iam2clt: we send a "doRunGracefully" which calls back with a "runConcurrentResultGracefully"?
;;; also need to pass the drone_count ...
(define doConcurrentRunGracefully (handle maude)
  (sinvoke "g2d.util.ActorMsg"  "send" maude handle "doRun")
  )



(define runConcurrentResultGracefully (handle maude val)
  (let ((statsObject (fetch handle)))
    (if (isobject statsObject)
	(seq
	 ;; (invoke statsObject "recordRunResult" (apply makeDouble val))
	 (invoke statsObject "recordRunResult" val)
	 (invoke java.lang.System.err "println" (concat "runResult from " maude " : " val ))
	 (sinvoke "g2d.util.ActorMsg"  "send" maude "g2d" "OK")
	 (apply doConcurrentStatGracefullysAux handle maude drone_count statsObject (invoke statsObject "done"))
	 )) ))

