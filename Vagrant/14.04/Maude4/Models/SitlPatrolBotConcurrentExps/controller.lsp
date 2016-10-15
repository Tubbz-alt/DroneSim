(define plambda_init_lsp
  (concat
   "\n"
   ";;;Editing is Futile: autogenerated by 'init.lsp'"
   "\n"
   "(import 'sys')"
   "\n"
   "(invoke sys.stderr 'write' 'initializing {0}\\n')"
   "\n"
   "(load 'drone.lsp')"
   "\n"
   "(define b0 (apply mkdrone 'b0' (int {1})))"
   "\n"
   "(import 'plambda.actors.actorlib')"
   "\n"
   "(apply plambda.actors.actorlib.send 'plambda' 'plambda{1}' 'initedOK plambda{1}')"
   "\n"
   )
  )

(define maude_init_maude
  (concat
   "\n"
   "**** Editing is Futile: autogenerated by 'init.lsp'"
   "\n"
   "load load_generic"
   "\n"
   "loop init ."
   "\n"
   "(seq\n (initAgentEset maude{0} g2d g2d plambda{0} SCENARIO asys3 OnePatrolBot)\n (augAgentEsetConcurrentStats Patrol 400))"
   "\n"
   )
  )
  

(define debug (boolean False))

(import 'sys')
(define logmsg (msg)
  (if debug 
      (invoke  sys.stderr 'write' msg)
    )
  )


(define clone_count (int 3))

(define plambda_clones (mklist))
(define plambda_population clone_count)

(define maude_clones (mklist))
(define maude_population clone_count)


(define make_args (prefix instanceno)
  (if (== prefix 'plambda')
      (concat  ' plambda' instanceno)
    (concat ' basura load'instanceno)))

(import 'plambda.actors.actorlib')
(define make_cloner (prefix executable clones count)
  (lambda (sender message)
    (let ((tokens (invoke message 'split')))
      (if (> (apply len tokens) (int 1))
	  (let ((verb (get tokens (int 0)))
		(noun (get tokens (int 1))))
	    (if (and (== verb 'startOK') (invoke noun 'startswith' prefix))
		(seq
		 (invoke clones 'append' noun)
		 (if (< (apply len clones) count)
		     (seq
		      (apply logmsg (concat 'Handled ' noun ' more coming\n'))
		      (let ((instanceno (apply len clones))
			    (name (concat prefix instanceno))
			    (args (apply make_args prefix instanceno)))
			(apply plambda.actors.actorlib.send
			       'system'
			       'plambda'
			       (concat 'start ' name ' ' executable ' ' args)))
		      )
		   (seq (apply logmsg (concat 'Handled ' noun ' enough already\n'))
			(apply init_clones clones prefix)
			)
		   )
		 (boolean true)
		 )
	      (seq
	       (boolean false)
	       )
	      )
	    )
	)
      )
    )
  )

(define inited_clones (mklist))

(define init_handler 
  (lambda (sender message)
    (let ((tokens (invoke message 'split')))
      (if (> (apply len tokens) (int 1))
	  (let ((verb (get tokens (int 0)))
		(noun (get tokens (int 1))))
	    (if (and (== verb 'initedOK') (invoke noun 'startswith' 'plambda'))
		(seq
		 (invoke inited_clones 'append' noun)
		 (if (== (apply len inited_clones) plambda_population)
		     (apply plambda.actors.actorlib.send 'g2d' 'plambda' '(load "g2dinit.lsp")'))
		 (boolean True)
		 )
	      )
	    )
	(boolean False)
	)
      )
    )
  )
     
	    
	    

(import 'plambda.util.Util')
(import 'time')
(define init_clones (clones prefix)
  (if (== prefix 'plambda')
      (seq
       (for clone clones
	    (let ((loadfile (concat 'init_' clone '.lsp'))
		  (contents (invoke plambda_init_lsp 'format' clone (invoke clones 'index' clone))))
	      (apply plambda.util.Util.string2File  contents loadfile (boolean False))
	      (apply plambda.actors.actorlib.send clone 'plambda' (concat '(load "' loadfile '")'))
	      )
	    )
       (apply plambda.actors.actorlib.send
	      'system'
	      'plambda'
	      (concat 'start maude0 iop_maude_wrapper ' (apply make_args 'maude' (int 0))))
       )
    )
  (if (== prefix 'maude')
      (seq
       (for clone clones
	    (seq 
	     (apply logmsg (concat 'clone: ' clone ' with prefix ' prefix '\n'))
	     )
	    )
       )
    )
  )



(define catchall
  (lambda (sender message)
    (invoke  sys.stderr 'write' (concat 'Handled: ' message ' from ' sender '\n'))))

(import 'plambda.actors.pyactor')

(apply plambda.actors.pyactor.add_handler
       (apply make_cloner 'plambda' 'pyactor' plambda_clones plambda_population))

(apply plambda.actors.pyactor.add_handler
       (apply make_cloner 'maude' 'iop_maude_wrapper' maude_clones maude_population))

(apply plambda.actors.pyactor.add_handler init_handler)

;;make the maude load files.
(for instanceno maude_population
     (let  ((loadfile (concat 'load' instanceno '.maude'))
	    (contents (invoke maude_init_maude 'format' instanceno)))
       (apply plambda.util.Util.string2File  contents loadfile (boolean False))))

;;start the ball rolling
(let ((name (concat 'plambda' (int 0))))
  (apply plambda.actors.actorlib.send 'system' 'plambda' (concat 'start ' name '  pyactor ' name))
  )


