(load "ergolib/init")
(require :ergolib)
(define-synonym display princ)
(define-synonym set! setf)
(define-synonym push! push)
(define-synonym inc! incf)
(define-synonym dec! decf)
(define-synonym integer? integerp)

(defv player-health nil)
(defv player-agility nil)
(defv player-strength nil)

(defv monsters nil)
(defv monster-builders nil)
(defc monster-num 12)

(defun orc-battle ()
  (init-monsters)
  (init-player)
  (game-loop)
  (when (player-dead?)
    (display "You have been killed. Game Over."))
  (when (monsters-dead?)
    (display "Congratulations! You have vanquished all of your foes."))
)

(defun game-loop ()
  (unless (or (player-dead?) (monsters-dead?))
    (show-player)
    (dotimes (_ (1+ (truncate (/ (max 0 player-agility) 15))))
      (unless (monsters-dead?)
        (show-monsters)
        (player-attack)
      ))
    (fresh-line)
    
    (for m in monsters collect
      (or (monster-dead? m) (monster-attack m)))
    (game-loop)
  ))

(defun init-player ()
  (set! player-health 30)
  (set! player-agility 30)
  (set! player-strength 30)
)

(defun player-dead? ()
  (<= player-health 0))

(defun show-player ()
  (fresh-line)
  (display "You are a valiant knight with a health of ")
  (display player-health)
  (display ", an agility of ")
  (display player-agility)
  (display ", and a strength of ")
  (display player-strength)
)

(defun player-attack ()
  (fresh-line)
  (display "Attack style: [s]tab  [d]ouble swing  [r]oundhouse:")
  (case (read)
    (s (monster-hit! (pick-monster)
                    (+ 2 (randval (ash player-strength -1)))))
    (d (bb x (randval (truncate (/ player-strength 6)))
         (display "Your double swing has a strength of ")
         (display x)
         (fresh-line)
         (monster-hit! (pick-monster) x)
         (unless (monsters-dead?)
           (monster-hit! (pick-monster) x)
         )))
    (otherwise (dotimes (x (1+ (randval (truncate (/ player-strength 3)))))
                 (unless (monsters-dead?)
                   (monster-hit! (random-monster) 1)
                 )))))

(defun randval (n)
  (1+ (random (max 1 n))))

(defun random-monster ()
  (bb m (ref monsters (random (length monsters)))
    (if (monster-dead? m)
      (random-monster)
      m
    )))

(defun pick-monster ()
  (fresh-line)
  (display "Monster #:")
  (bb x (read)
    (if (not (and (integer? x) (>= x 1) (<= x monster-num)))
      (progn (display "That is not a valid monster number.")
             (pick-monster))
      (bb m (ref monsters (1- x))
        (if (monster-dead? m)
          (progn (display "That monster is already dead.")
                 (pick-monster))
          m
        )))))

(defun init-monsters ()
  (set! monsters
        (for x in (make-array monster-num) vcollect
          (funcall (ref monster-builders
                        (random (length monster-builders))))
        )))

(defun monster-dead? (m)
  (<= (monster-health m) 0))

(defun monsters-dead? ()
  (every #'monster-dead? monsters))

(defun show-monsters ()
  (fresh-line)
  (display "Your foes:")
  (bb x 0
    (for m in monsters collect (progn
      (fresh-line)
      (display "  ")
      (display (inc! x))
      (display ". ")
      (if (monster-dead? m)
        (display "**dead**")
        (progn (display "(Health=")
               (display (monster-health m))
               (display ") ")
               (monster-show m)
        ))))))

(defstruct monster (health (randval 10)))

(define-method (monster-hit! (m monster health) x)
  (dec! health x)
  (if (monster-dead? m)
    (progn (display "You killed the ")
           (display (type-of m))
           (display "! "))
    (progn (display "You hit the ")
           (display (type-of m))
           (display ", knocking off ")
           (display x)
           (display " health points! "))
  ))

(defmethod monster-show (m)
  (display "A fierce ")
  (display (type-of m))
)

(defmethod monster-attack (m))

(defstruct (orc (:include monster)) (club-level (randval 8)))
(push! #'make-orc monster-builders)

(define-method (monster-show (_ orc club-level))
  (display "A wicked orc with a level ")
  (display club-level)
  (display " club")
)

(define-method (monster-attack (_ orc club-level))
  (bb x (randval club-level)
    (display "An orc swings his club at you and knocks off ")
    (display x)
    (display " of your health points. ")
    (dec! player-health x)
  ))

(defstruct (hydra (:include monster)))
(push! #'make-hydra monster-builders)

(define-method (monster-show (_ hydra health))
  (display "A malicious hydra with ")
  (display health)
  (display " heads.")
)

(define-method (monster-hit! (m hydra health) x)
  (dec! health x)
  (if (monster-dead? m)
    (display "The corpse of the fully decapitated and decapacitated hydra falls to the floor!")
    (progn (display "You lop off ")
           (display x)
           (display " of the hydra's heads! "))
  ))

(define-method (monster-attack (_ hydra health))
  (bb x (randval (ash health -1))
    (display "A hydra attacks you with ")
    (display x)
    (display " of its heads! It also grows back one more head! ")
    (inc! health)
    (dec! player-health x)
  ))

(defstruct (slime-mold (:include monster)) (sliminess (randval 5)))
(push! #'make-slime-mold monster-builders)

(define-method (monster-show (_ slime-mold sliminess))
  (display "A slime mold with a sliminess of ")
  (display sliminess)
)

(define-method (monster-attack (_ slime-mold sliminess))
  (bb x (randval sliminess)
    (display "A slime mold wraps around your legs and decreases your agility by ")
    (display x)
    (display "! ")
    (dec! player-agility x)
    (when (zero? (random 2))
      (display "It also squirts in your face, taking away a health point! ")
      (dec! player-health)
    )))

(defstruct (brigand (:include monster)))
(push! #'make-brigand monster-builders)

(defmethod monster-attack ( (m brigand) )
  (bb x (max player-health player-agility player-strength)
    (mcond
      (= x player-health)
        (progn (display "A brigand hits you with his slingshot, taking off 2 health points! ")
               (dec! player-health 2))
      (= x player-agility)
        (progn (display "A brigand catches your leg with his whip, taking off 2 agility points! ")
               (dec! player-agility 2))
      (= x player-strength)
        (progn (display "A brigand cuts your arm with his whip, taking off 2 strength points! ")
               (dec! player-strength 2))
    )))

