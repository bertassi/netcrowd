; Global variables.
globals [
  globalExecutedTasks
  globalActiveTasks
  workerColor
  taskColor
  taskLinkColor
  workerSplotchColor
  taskSplotchColor patchColor
  workerSize
  taskSize
  linkSize
  workerShape
  taskShape
  labelColor
  maximizationCriteria
]

;;--------------------------------------------------------------------------------------------------------

; Workers' breed.
breed [workers worker]

; Workers' attributes.
workers-own
[
  workerMotivation
  workerSkill
  workerReputation
]

;;--------------------------------------------------------------------------------------------------------

; Tasks' breed.
breed [tasks task]

; Tasks' attributes.
tasks-own
[
  taskDifficulty
  taskReward
  taskReputation
  taskDistanceFromWorker
  taskXCord
  taskYCord
  isAssigned?
]

;;--------------------------------------------------------------------------------------------------------

; Links' breed.
directed-link-breed [ task_links task_link ]

;;--------------------------------------------------------------------------------------------------------

; Procedure to set global variables.
to SetupGlobals

  ; Initialize the executed tasks global counter.
  set globalExecutedTasks 0

  ; Initialize the active tasks global counter.
  set globalActiveTasks 0

  ; Set the patch color.
  set patchColor black

  ; Set the workers characteristics.
  set workerShape "person"
  set workerColor yellow
  set workerSize 1
  set workerSplotchColor grey

  ; Set the tasks characteristics.
  set taskShape "target"
  set taskColor red
  set taskSize 1
  set taskSplotchColor orange

  ; Set the links characteristics.
  set taskLinkColor workerColor
  set linkSize 0.2

  ; Color of all labels used in the simulation.
  set labelColor white

  ; Maximization criteria initialization.
  set maximizationCriteria 0

  ; There were some ocasions that Netlogo set the following simulation variables to zero when the  simula-
  ; tion file gets opened. Therefore, to avoid runtime errors at the beginning, it was decided to  initia-
  ; lize the following variables:

  if (Degrees = 0)
  [ set Degrees 30 ]

  if (WorkerTaskPerceptionRadius = 0)
  [ set WorkerTaskPerceptionRadius 5]

  if(WorkerMaxMotivation = 0)
  [ set WorkerMaxMotivation 100]

  if(WorkerMaxSkill = 0)
  [set WorkerMaxSkill 100 ]

  if(WorkerMaxReputation = 0)
  [ set WorkerMaxReputation 100]

  if(InitialWorkersAmount = 0)
  [ set InitialWorkersAmount 1]

  if(InitialTasksAmount = 0)
  [ set InitialTasksAmount 1]

  if(TaskMaxDifficulty = 0)
  [ set TaskMaxDifficulty 1]

  if(MaxSimulationTicks = 0)
  [ set MaxSimulationTicks 1000]

  if(SkillLearningCurveType = "")
  [ set SkillLearningCurveType "Ln"]

  if (MaximizationCriterium = "")
  [ set MaximizationCriterium "None"]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to set the execution environment.
to SetupEnvironment

  ask patches
  [ set pcolor patchColor ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to set initial workers.
to SetupWorkers

  ; Create a certain initial workers amount according to the "InitialWorkersAmount" slider.
  createWorkers InitialWorkersAmount

end

;---------------------------------------------------------------------------------------------------------

; Procedue to set initial tasks.
to SetupTasks

  ; Create a certain initial tasks amount according to the "InitialTasksAmount" slider.
  createTasks InitialTasksAmount

end

;;--------------------------------------------------------------------------------------------------------

; Modular procedure to create new workers from any part of the code.
;; workersAmount   : Workers amount parameter (from the slider).
to CreateWorkers [workersAmount]

  set-default-shape workers workerShape

  ; This piece of code assures that it will never exist more than 1000 workers in the environment, despite
  ; the AddNewWorkerRate.
  if (((count workers) + workersAmount) > 1000)
  [
    set workersAmount 1000 - (count workers)
  ]

  ; Create workers.
  if (count workers <= 1000)
  [
    create-workers workersAmount
    [
      setxy random-xcor random-ycor
      set label-color labelColor
      set color workerColor
      set size workerSize

      ; workerMotivation value between 0 to 100
      set workerMotivation random WorkerMaxMotivation + 1

      ; workerSkill value between 0 to 100
      set workerSkill random WorkerMaxSkill + 1

      ; Reputation will increase according to the workers' performance, but always starts with  "1".  This
      ; will affect the worker's quality output of his work. Initially, it starts at the lowest level pos-
      ; sible. The worker should earn more reputation by working.
      set workerReputation 1

      ; workerMotivation and workerSkill can never be zero at the beggining of the simulation.
      while [ (workerMotivation = 0) or (workerSkill = 0) ]
      [
        if workerMotivation = 0
        [ set workerMotivation 1 ]

        if workerSkill = 0
        [ set workerSkill 1 ]
      ]

      ; If ForceEndlessMotivation is true it makes no sense to show the workers' motivation label.
      ifelse (ForceEndlessMotivation = true)
      [ set label "" ]
      [ set label workerMotivation ]
    ]
  ]

end

;;--------------------------------------------------------------------------------------------------------

; Modular procedure to create new tasks from any part of the code.
;; tasksAmount   : Tasks amount parameter (from the slider).
to CreateTasks [tasksAmount]

  set-default-shape tasks taskShape

  ; This piece of code assures that it will never exist more than 1000 tasks in the environment,  despite
  ; the AddNewTaskRate.
  if (((count tasks) + tasksAmount) > 1000)
  [
    set tasksAmount 1000 - (count tasks)
  ]

  ; Create tasks.
  if (count tasks <= 1000)
  [
    create-tasks tasksAmount
    [
      ; Necessary to round the value or workers will wander erratically.
      set taskXCord round random-xcor
      set taskYCord round random-ycor

      ; Prevents a new task to be placed over another existing task in the environment.
      while [any? tasks-on patch taskXCord taskYCord]
      [
        set taskXCord round random-xcor
        set taskYCord round random-ycor
      ]

      ; Once a suitable xcor and ycor is found, it sets this value to the task.
      setxy taskXCord taskYCord

      set label-color labelColor
      set color taskColor
      set size taskSize

      ; taskDifficulty value between 0 to 100
      set taskDifficulty random TaskMaxDifficulty + 1

      ; taskReward value between 0 to 100
      set taskReward random TaskMaxReward + 1

      set taskReputation 0
      set taskDistanceFromWorker 0

      ; Values must be between 1 to TaskMaxDifficulty or TaskMaxReward.
      while [ (taskDifficulty = 0) or (taskReward = 0) ]
      [
        if (taskDifficulty = 0)
        [ set taskDifficulty random TaskMaxDifficulty + 1 ]

        if (taskReward = 0)
        [ set taskReward random TaskMaxReward + 1 ]
      ]
      set label taskReward
    ]
  ]
end

;;--------------------------------------------------------------------------------------------------------

to AddWorkers

  let valor random 100

  ;; O código abaixo serve para simular uma situação de "N" trabalahadores novos entrando no sistema pela primeira vez.
  ;; Note que o código coloca um número randômico de trabalahdores em x% das vezes que é executado, conforme o slider
  ;; "taxadeRecriacaoDeTrabalhadores".
  if (random 100) < AddNewWorkersRate
  [ CreateWorkers NewWorkersAmount ]

end

;;--------------------------------------------------------------------------------------------------------

; The code below serves to simulate a situation where the crowdsourcing environment gets "N" new  workers
; after a certain period of time. Note that the code places a workers random number at x% of the times it
; executes as determined by the AddNewTasksRate slider.
to AddTasks

  let valor random 100

  ;; O código abaixo serve para simular uma situação de "N" trabalahadores novos entrando no sistema pela primeira vez.
  ;; Note que o código coloca um número randômico de trabalahdores em x% das vezes que é executado, conforme o slider
  ;; "taxadeRecriacaoDeTrabalhadores".
  if (random 100) < AddNewTasksRate
  [ CreateTasks NewTasksAmount ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure show were the workers are going.
to ShowWorkerPath

  ifelse ShowWorkersPath
  [ ask workers [ pen-down ]]
  [ ask workers [ pen-up ]]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to make the task radius visible for debugging.
to MakeTaskSplotch

  ifelse ShowTaskSplotch
  [
    ask tasks
    [
      ask patch-here
      [
        set pcolor taskSplotchColor
      ]
    ]
  ]
  [
    ask patches
    [
      if pcolor = taskSplotchColor
      [
        set pcolor patchColor
      ]
    ]
  ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to make the worker PerceptionRadius visible for debugging.
to MakeWorkerSplotch

  ifelse ShowWorkerSplotch
  [
    clear-patches

    ask workers
    [
      ask patches in-radius WorkerTaskPerceptionRadius
      [
        set pcolor workerSplotchColor
      ]
    ]
  ]
  [
    ask patches
    [
      if pcolor = workerSplotchColor
      [
        set pcolor patchColor
      ]
    ]
  ]

end

;;--------------------------------------------------------------------------------------------------------

;  Procedure for checking if it is possible to enable maximization criteria.
to CheckMaximizationCriteria

  ; If SearchNearestTask is false, it doesn't make sense to make workers choose a maximization  criterium,
  ; since tasks will be randomly executed.
  if (SearchNearestTask = false)
  [
    set MaximizationCriterium "None"
  ]

end

;---------------------------------------------------------------------------------------------------------

; Procedure to set the simulation environment.
to setup

  ; Clear-globals, clear-ticks, clear-turtles, clear-patches, clear-drawing, clear-all-plots,  and  clear-
  ; output.
  clear-all

  ; Depending on the search task strategy and on the maximization criteria some switches must  be  setted
  ; correctly.
  CheckMaximizationCriteria

  SetupGlobals
  SetupEnvironment
  SetupWorkers
  SetupTasks

  ; Resets the tick counter to zero, sets up all plots, then updates all plots initial states.
  reset-ticks

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to execute each simulation step.
to go

  if (debug)
  [print "" type "##--------------------------- Step " type ticks print " ---------------------------##" print ""]

  ; Depending on the search task strategy and on the maximization criteria some switches must  be  setted
  ; correctly.
  CheckMaximizationCriteria

  ; These three procedures help to debug the simulation and to make the workers activity more visible.
  ShowWorkerPath
  MakeWorkerSplotch
  MakeTaskSplotch

  ; These three procedures are responsible for commanding all workers behaviour.
  AssignTask
  ExecuteTask
  MoveWorker

  ; These two procedures allows us to study a crowdsourcing environment on  a  steady  state,  i.e.  when
  ; there's a situation that eighter workers or tasks are being constantly created.
  AddWorkers
  AddTasks

  if (debug) [ print "" type "##------------------------- End Step " type ticks print " -------------------------##" print ""]

  ; Disable the simulation maximum ticks amount.
  if (EnableTickCount = false)
  [
    ifelse ((count workers = 0) or (count tasks = 0))
    [
      ; Shows why the simulation has stopped.
      if (count workers = 0) [ print "" type "#################### End of Simulation -> Reached 0 Workers in " type ticks print " ticks ####################" print ""]
      if (count tasks = 0) [ print "" type "#################### End of Simulation -> Reached 0 Tasks in " type ticks print " ticks ####################" print ""]

      stop
    ]
    [ tick ]
  ]

  ; Enable the simulation maximum ticks amount.
  if (EnableTickCount = true)
  [
    ifelse ((count workers = 0) or (count tasks = 0) or (ticks = MaxSimulationTicks))
    [
      ; Shows why the simulation has stopped.
      if (count workers = 0) [ print "" type "#################### End of Simulation -> Reached 0 Workers in " type ticks print " ticks ####################" print ""]
      if (count tasks = 0) [ print "" type "#################### End of Simulation -> Reached 0 Tasks in " type ticks print " ticks ####################" print ""]
      if (ticks = MaxSimulationTicks) [ print "" type "#################### End of Simulation -> Reached MaxSimulationTicks in " type ticks print " ticks ####################" print ""]

      stop
    ]
    [ tick ]
  ]

end

;;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;;---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

; Procedure to calculate the worker's reputation after executing a task. Higher work motivation, skill,
; reputation values and task difficulty values will grant better reputation scores.
to-report CalculateReputation [worker_motivation worker_skill worker_current_reputation task_difficulty distance_from_task]

  let skillGrade 0
  let reputationGrade 0

  ; Reputation will be a value between 0 to 10.
  let reputation round ln (((1 * worker_motivation) +
                    (2 * worker_skill) +
                    (3 * worker_current_reputation) +
                    (4 * task_difficulty) ) / 10)

  ; Quanto mais longe, pior a reputação.
  ; report (reputation * (1 - ( distance_from_task / WorkerTaskPerceptionRadius )))

  ; Quanto mais inexperiente, pior chance de o trabalho ser ruim.
  if ((1 <= worker_skill) and (worker_skill <= 33))
  [
    ;print "" type "Worker Skill = Novice(" type worker_skill print ")"
    set skillGrade 1
  ] ; Novice

  if ((34 <= worker_skill) and (worker_skill <= 66))
  [
    ;print "" type "Worker Skill = Associate(" type worker_skill print ")"
    set skillGrade 2
  ]; Associate

  if ((67 <= worker_skill) and (worker_skill <= 100))
  [
    ;print "" type "Worker Skill = Senior(" type worker_skill print ")"
    set skillGrade 3
  ]; Senior

  ; // ---------------------- // ---------------------- //

  if ((1 <= worker_current_reputation) and (worker_current_reputation <= 33))
  [
    ;type "Worker Reputation = Novice(" type worker_current_reputation print ")"
    set reputationGrade 1
  ]; Novice

  if ((34 <= worker_current_reputation) and (worker_current_reputation <= 66))
  [
    ;type "Worker Reputation = Associate(" type worker_current_reputation print ")"
    set reputationGrade 2
  ]; Associate

  if ((67 <= worker_current_reputation) and (worker_current_reputation <= 100))
  [
    ;type "Worker Reputation = Senior(" type worker_current_reputation print ")"
    set reputationGrade 3
  ]; Senior

  ; // ---------------------- // ---------------------- //

  if ((skillGrade + reputationGrade) >= 5)
  [
    ;print "Task Execution will be Accepted!" print ""
    report reputation ; Accepts the job
  ]

  if ((skillGrade + reputationGrade) = 4)
  [
    ifelse (random 100 >= 50)
    [
      ;print "Task Execution will be Accepted!" print ""
      report reputation ; Accepts the job
    ]
    [
      ;print "Task Execution will be Rejected!" print ""
      report reputation * -1 ; Rejects the job
    ]
  ]

  if ((skillGrade + reputationGrade) <= 3)
  [
    ;print "Task Execution will be Rejected!" print ""
    report reputation * -1 ; Rejects the job
  ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to find the next task that will be executed by workers.
to-report FindTask [currentWorker]

  let nearestTask 0

  ask currentWorker
  [
    let tmpWorkerSkill workerSkill
    let tmpWorkerMotivation workerMotivation
    let tmpWorkerReputation workerReputation
    let parameter 0
    let tasksSet nobody

    let tmpTaskDistanceFromWorker 0
    let tmpTaskReputation 0

    if (debug)
    [type "----- Tasks Nearby Worker " type who print " -----"]

; ############################################################################### maximize MOTIVATION ########################################################################################

    ;; To maximizeMOTIVATION the worker should priorize tasks with higher REWARDS (considering his skills)
    if (MaximizationCriterium = "Motivation")
    [
      ifelse (AvoidTaskExecutionConcurrence)
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação e que não estejam sendo executadas por outros.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius) and not any? in-task_link-neighbors]
      ]
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius)]
      ]

      ; Aproveito para calcular a reputação mo momento da descoberta da tarefa.
      ask tasksSet
      [
        set taskDistanceFromWorker distance myself
        set taskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty taskDistanceFromWorker

        if (debug)
        [type "MAX-MOTIVATION - Task(" type who type"): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type "; Distance from Worker=" print taskDistanceFromWorker]
      ]

      if (debug)
      [print ""]

      ; Do conjunto original de tarefas, pego as tarefas com a maior recompensa.
      let agentsWithMaxReward tasksSet with-max [ taskReward ]

      ; Do conjunto das tarefas com maior recompensa, pego aquelas que estão mais próximas.
      ; TODO: O objetivo é pegar as tarefas de maior recompensa. Nem tanto as tarefas mais próximas ( o que importa é que elas
      ;       estejam no no raio de ação do agente.
      let agentsWithMinDistanceFromWorker agentsWithMaxReward with-min [ taskDistanceFromWorker ]

      let tempNearestTask min-one-of (agentsWithMinDistanceFromWorker)
      [
        taskDistanceFromWorker
      ]

      if (debug)
      [
        if (tempNearestTask != nobody)
        [
          ask tempNearestTask
          [
            type "Best task to assign - Task(" type who type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type " ; Distance from worker=" print taskDistanceFromWorker print ""
          ]
        ]
      ]

      set nearestTask tempNearestTask
    ]

; ############################################################################### maximize SKILL ########################################################################################

    ;; To maximizeSKILL the worker should priorize tasks with higher DIFFICULTY levels (considering his skills)
    if (MaximizationCriterium = "Skill")
    [
      ifelse (AvoidTaskExecutionConcurrence)
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação e que não estejam sendo executadas por outros.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius) and not any? in-task_link-neighbors]
      ]
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius)]
      ]

      ; Aproveito para calcular a reputação mo momento da descoberta da tarefa.
      ask tasksSet
      [
        set taskDistanceFromWorker distance myself
        set taskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty taskDistanceFromWorker

        if (debug)
        [type "MAX-SKILL - Task(" type who type"): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type "; Distance from Worker=" print taskDistanceFromWorker]
      ]

      if (debug)
      [print ""]

      ; Do conjunto original de tarefas, pego as tarefas com a maior dificuldade.
      let agentsWithMaxDifficulty tasksSet with-max [ taskDifficulty ]

      ; Do conjunto das tarefas com maior difuculdade, pego aquelas que estão mais próximas.
      let agentsWithMinDistanceFromWorker agentsWithMaxDifficulty with-min [ taskDistanceFromWorker ]

      ;; To maximizeSKILL the worker should priorize tasks with MAX difficulty (considering his skills). Pego a tarefa que possui a maior dificuldade e a menor distância.
      let tempNearestTask min-one-of (agentsWithMinDistanceFromWorker)
      [
        taskDistanceFromWorker
      ]

      if (debug)
      [
        if (tempNearestTask != nobody)
        [
          ask tempNearestTask
          [
            type "Best task to assign - Task(" type who type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type " ; Distance from worker=" print taskDistanceFromWorker print ""
          ]
        ]
      ]

      set nearestTask tempNearestTask
    ]

; ############################################################################### maximize REPUTATION ########################################################################################

    ;; To maximizeREPUTATION
    if (MaximizationCriterium = "Reputation")
    [
      ifelse (AvoidTaskExecutionConcurrence)
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação e que não estejam sendo executadas por outros.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius) and not any? in-task_link-neighbors]
      ]
      [
        ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação.
        set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius)]
      ]

      ; Aproveito para calcular a reputação mo momento da descoberta da tarefa.
      ask tasksSet
      [
        set taskDistanceFromWorker 0
        set taskReputation 0

        set taskDistanceFromWorker distance myself
        set taskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty taskDistanceFromWorker

        if (debug)
        [type "MAX-REPUTATION - Task(" type who type"): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type "; Distance from Worker=" print taskDistanceFromWorker]

      ]

      if (debug)
      [print ""]

      ; Do conjunto original de tarefas, pego as tarefas com a maior reputação.
      let agentsWithMaxReputation tasksSet with-max [ taskReputation ]

      ; Do conjunto das tarefas com maior reputação, pego aquelas que estão mais próximas.
      let agentsWithMinDistanceFromWorker agentsWithMaxReputation with-min [ taskDistanceFromWorker ]

      ;; To maximizeREPUTATION the worker should priorize tasks with MAX EstimateReputation (considering his skills). Pego a tarefa que possui a maior reputação e a menor distância possível.
      let tempNearestTask min-one-of (agentsWithMinDistanceFromWorker)
      [
        taskDistanceFromWorker
      ]

      if (debug)
      [
        if (tempNearestTask != nobody)
        [
          ask tempNearestTask
          [
            type "Best task to assign - Task(" type who type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type " ; Distance from worker=" print taskDistanceFromWorker print ""
          ]
        ]
      ]

      set nearestTask tempNearestTask
    ]

; ############################################################################### NO MAXIMIZATION ########################################################################################

    ; NO MAXIMIZATION criteria.
    if (MaximizationCriterium = "None")
    [
        ifelse (AvoidTaskExecutionConcurrence)
        [
          ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação e que não estejam sendo executadas por outros.
          set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius) and not any? in-task_link-neighbors]
        ]
        [
          ; Pego todas as tarefas que podem ser executadas pelo trabalhador, mas que estejam dentro do seu raio de ação.
          set tasksSet tasks with [ (taskDifficulty <= tmpWorkerSkill) and (distance myself <= WorkerTaskPerceptionRadius)]
        ]

      ; Aproveito para calcular a reputação mo momento da descoberta da tarefa.
      ask tasksSet
      [
        set taskDistanceFromWorker 0
        set taskReputation 0

        set taskDistanceFromWorker distance myself
        set taskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty taskDistanceFromWorker

        if (debug)
        [type "NO MAXIMIZATION - Task(" type who type"): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type " ; Distance from Worker=" print taskDistanceFromWorker]

      ]

      if (debug)
      [print ""]

      ; Simplesmente executo a tarefa mais próxima.
      let tempNearestTask min-one-of (tasksSet)
      [
        taskDistanceFromWorker
      ]

      if (debug)
      [
        if (tempNearestTask != nobody)
        [
          ask tempNearestTask
          [
            type "Best task to assign - Task(" type who type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type taskReputation type " ; Distance from worker=" print taskDistanceFromWorker print ""
          ]
        ]
      ]

      set nearestTask tempNearestTask
    ]

; #######################################################################################################################################################################

  ]

  report nearestTask

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to assign tasks to workers.
to AssignTask

  ; Não é preciso atribuir uma tarefa quando SearchNearestTask é false pois os trabalhadores executarão as
  ; tarefas à medida que caminham pelo ambiente.
  if (SearchNearestTask = true)
  [
    ; Free workers have no links attached to them.
    let free_workers workers with [not any? out-task_link-neighbors]

    ; Busy workers have links attached to them.
    ; TODO: This line of code seems not necessary here. Check if we can remove.
    let busy_workers workers with [any? out-task_link-neighbors]

    ask free_workers
    [
      let assigned_task FindTask self

      if (assigned_task != nobody)
      [
        ; O link indica para onde o worker deve rumar para executar uma tarefa.
        create-task_link-to assigned_task
        [
          set color taskLinkColor
          set thickness linkSize

          ; Quando a tarefa é selecionada ela ganha a cor do link até que seja executada.
          ask other-end
          [ set color taskLinkColor ]

          ifelse(ShowWorkerLinkedTask = false)
          [ hide-link ]
          [ show-link ]

        ]
      ]
    ]

    ; Código para assegurar que se o link do trabalhador com a tarefa estiver fora do raio de atuação do
    ; trabalhador o link será desfeito.
    ; TODO: Aparentemente esse pedaço de código nunca está sendo executado. É preciso revisar.
    ask busy_workers
    [
      ask my-out-task_links
      [
        if (link-length > WorkerTaskPerceptionRadius)
        [
          ask other-end
          [ set color taskColor ]
          die
        ]
      ]
    ]
  ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to make workers execute a task once it has been assigned to them.
to ExecuteTask

  ; Though not necessary, this variable is created just to improve source code readability.
  let taskExecuted? false

  ; If SearchNearestTask is true, workers will only execute tasks that were assigned to them. Thus, it  is
  ; possible to apply different task execution maximization criteria (motivation, skill or reputation).
  if (SearchNearestTask = true)
  [
    ; We just need to command the busy workers, i.e. workers that have a task_link to a task.
    let busy_workers workers with [any? out-task_link-neighbors]

    ask busy_workers
    [
      ; Temporary variables are necessary if we wnat to access workers' and tasks' attributes in  differ-
      ; ent contexts (worker-context; task-context; patch-context; link-context).
      let tmpWorkerMotivation workerMotivation
      let tmpWorkerSkill workerSkill
      let tmpWorkerReputation workerReputation
      let tmpWorkerXCor 0
      let tmpWorkerYCor 0
      let workerID 0

      let tmpTaskDifficulty 0
      let tmpTaskReward 0
      let tmpTaskReputation 0
      let tmpTaskXCor 0
      let tmpTaskYCor 0
      let taskID 0

      ; Get the worker's ID and coordinates. Note that xcor and ycor are in the worker-context.
      set tmpWorkerXCor xcor
      set tmpWorkerYCor ycor
      set workerID who

      if (debug)
      [ type "Worker(" type workerID type ")- Coordinates: (" type tmpWorkerXCor type ", " type tmpWorkerYCor print ")" ]

      ; If the worker has an assigned task, the out-task_link allows us to access the task attributes  of
      ; his assigned task.
      ask my-out-task_links
      [
        ; Accessing the task attributes. The following piece of code enters the task-context.
        ask other-end
        [
          ; Get the task's ID and coordinate. Note that, now, xcor and ycor are in the task-context.
          set tmpTaskXCor xcor
          set tmpTaskYCor ycor
          set taskID who

          if (debug)
          [ type "Task(" type taskID type ")- Coordinates: (" type tmpTaskXCor type ", " type tmpTaskYCor print ")" print ""]
        ]
      ]

      ; This piece of code turns the workers' coordinates into a integer value,  instead  of  a  floating
      ; point value. If workers move through the patch/environment using floating point values they  will
      ; have problems when trying to match the task coordinates for executing them.
      if ((round tmpWorkerXCor = tmpTaskXCor) and (round tmpWorkerYCor = tmpTaskYCor))
      [
        ; If the worker is near to the task he was assigned to, the Worker gets the task coordinates.This
        ; corrects the worker trajectory in the environment towards his assigned task.
        setxy tmpTaskXCor tmpTaskYCor

        ; Update the temporary variables to be used in other contexts.
        set tmpWorkerXCor xcor
        set tmpWorkerYCor ycor

        if (debug)
        [ type "Worker(" type workerID type ") corrected its coordinates to: (" type xcor type ", " type ycor print ")"]
      ]

      ; If there is a task in the same xcor and ycor coordinates where the worker is  the  task  will  be
      ; executed. Otherwise, the worker will keep wandering in the environment until a task  be  assigned
      ; to him.
      if ((tmpWorkerXCor = tmpTaskXCor) and (tmpWorkerYCor = tmpTaskYCor))
      [
        ; Remember that this entire source code avoids the creation of two tasks on the same patch,  which  means  that
        ; there will be only one task in the xcor and ycor coordinates to be executed.
        ask tasks-on patch xcor ycor
        [
          ; Gets all task's attributes values to use them in another context.
          set tmpTaskDifficulty taskDifficulty
          set tmpTaskReward taskReward
          set tmpTaskReputation taskReputation

          ; If the worker has the necessary skill to execute a task, he will execute it.
          if (tmpWorkerSkill >= tmpTaskDifficulty)
          [
            ; Marks the task as executed (not necessary... that's just to improve code readability).
            set taskExecuted? true

            if (debug)
            [
              let distanceFromWorker distance myself
              set tmpTaskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty distanceFromWorker
              type "Worker(" type workerID type ") executed Task(" type taskID type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type tmpTaskReputation type " ; Distance from Worker=" print distanceFromWorker print ""
            ]

            ask patch xcor ycor
            [
              if (ShowTaskSplotch)
              [
                ifelse (ShowWorkerSplotch)
                [ set pcolor workerSplotchColor ]
                [ set pcolor patchColor ]
              ]
            ]

            ; Kills the task to indicate that it has been executed.
            die
          ]

          ; If the worker dos not have the necessary skill to execute a task, he will not execute it.
          if (tmpWorkerSkill < tmpTaskDifficulty)
          [
            ; Marks the task as NOT executed (not necessary... that's just to improve code readability).
            set taskExecuted? false

            ; Makes sure that the task will have its original color (not necessary... that's just to improve code readability).
            set color taskColor

            ; Makes sure that no undesired link is active by killing them (not necessary... that's just to improve code readability).
            ask my-links
            [ die ]
          ]
        ]

        ; If the task was marked as executed...
        if (taskExecuted? = true)
        [
          ; Update the globalExecutedTasks
          set globalExecutedTasks globalExecutedTasks + 1

          ; In this simulation environment, workerSkill will always increase.  It  is  assumed  that  the
          ; worker will never loose his skills. By default, we choosed to use a averaged  learning  curve
          ; (based  on "ln") to indicate slow skill increases at first followed by larger  skill  increa-
          ; ses, and  then successively smaller ones later, as the learning activity reaches  its  limit.
          ; However, we offer 3 types of learning curves: linear, ln, and sigmoid (i.e. 1 /(1+exp(-x)) ).
          if (SkillLearningCurveType = "Linear")
          [
            set workerSkill ( workerSkill + tmpTaskDifficulty )
          ]
          if (SkillLearningCurveType = "Ln")
          [
            set workerSkill ( workerSkill + (ln tmpTaskDifficulty ) )
          ]
          if (SkillLearningCurveType = "Sigmoid")
          [
            set workerSkill (workerSkill + (1 / ( 1 + (exp ( (-1) * tmpTaskDifficulty ) ) ) ) )
          ]

          ; The workerSkill cannot be higher than WorkerMaxSkill.
          if (workerSkill > WorkerMaxSkill)
          [ set workerSkill WorkerMaxSkill]

          ; Set the workerReputation that has been calculated.
          set workerReputation workerReputation + tmpTaskReputation

          ; The workerReputation cannot be higher than WorkerMaxReputation.
          if (workerReputation > WorkerMaxReputation)
          [ set workerReputation WorkerMaxReputation]

          ; The workerReputation cannot be lower than 1.
          if (workerReputation < 1)
          [ set workerReputation 1]

          ; In the real world, workers need to be motivated with some reward. For debuggig  purposes,  we
          ; can turn off the motivation verification.
          if (not ForceEndlessMotivation)
          [
            ; The reward increases the worker's motivation.
            set workerMotivation workerMotivation + tmpTaskReward

            ; The workerMotivation cannot be higher than WorkerMaxMotivation.
            if (workerMotivation > WorkerMaxMotivation)
            [ set workerMotivation WorkerMaxMotivation ]

            ; Updates the worker's motivation label being shown in the simulation.
            set label workerMotivation
          ]
        ]
      ]
    ]
  ]

  ; If SearchNearestTask is false, workers will execute any task they find on their  way.  Therefore,  no
  ; task execution maximization criteria can be applied.
  if (SearchNearestTask = false)
  [
    ask workers
    [
      let tmpWorkerMotivation workerMotivation
      let tmpWorkerSkill workerSkill
      let tmpWorkerReputation workerReputation
      let workerID who

      let tmpTaskDifficulty 0
      let tmpTaskReward 0
      let tmpTaskReputation 0
      let taskID 0

      let distanceFromWorker 0

      ; Se existir alguma tarefa onde o trabalhador estiver passando ele a executa (se possuir habilidade
      ; para tal).
      ; If theres a task
      if (any? tasks-on patch xcor ycor)
      [
        ; Lembrando que a simulação nunca coloca mais de uma tarefa no mesmo patch. Então não é preciso se preocupar
        ; com superposição de tarefas.
        let currentTask tasks-on patch xcor ycor

        ; Remember that this code avoids the creation of two tasks on the same patch.
        ; Therefore, there will br only one task per patch.
        ask currentTask
        [
          ifelse (tmpWorkerSkill >= taskDifficulty)
          [
            set tmpTaskDifficulty taskDifficulty
            set tmpTaskReward taskReward
            set tmpTaskReputation CalculateReputation tmpWorkerMotivation tmpWorkerSkill tmpWorkerReputation taskDifficulty distanceFromWorker
            set taskID who
            set taskColor yellow


            if (debug)
            [
              type "Worker(" type workerID type ") executed Task(" type taskID type "): Difficulty=" type taskDifficulty type " ; Reward=" type taskReward type " ; Reputation=" type tmpTaskReputation type " ; Distance from Worker=" print distanceFromWorker print ""
            ]

            if (ShowTaskSplotch)
            [
              ifelse (ShowWorkerSplotch)
              [ set pcolor workerSplotchColor ]
              [ set pcolor patchColor ]
            ]

            set taskExecuted? true

            ; Kills the task to indicate that it has been executed and, then, update ther worker's attri-
            ; butes.
            die
          ]
          [
            set taskExecuted? false
          ]
        ]

        ; If the task was marked as executed...
        if (taskExecuted? = true)
        [
          ; Update the globalExecutedTasks
          set globalExecutedTasks globalExecutedTasks + 1

          ; In this simulation environment, workerSkill will always increase.  It  is  assumed  that  the
          ; worker will never loose his skills. By default, we choosed to use a averaged  learning  curve
          ; (based  on "ln") to indicate slow skill increases at first followed by larger  skill  increa-
          ; ses, and  then successively smaller ones later, as the learning activity reaches  its  limit.
          ; However, we offer 3 types of learning curves: linear, ln, and sigmoid (i.e. 1 /(1+exp(-x)) ).
          if (SkillLearningCurveType = "Linear")
          [
            set workerSkill ( workerSkill + tmpTaskDifficulty )
          ]
          if (SkillLearningCurveType = "Ln")
          [
            set workerSkill ( workerSkill + (ln tmpTaskDifficulty ) )
          ]
          if (SkillLearningCurveType = "Sigmoid")
          [
            set workerSkill (workerSkill + (1 / ( 1 + (exp ( (-1) * tmpTaskDifficulty ) ) ) ) )
          ]

          ; The workerSkill cannot be higher than WorkerMaxSkill.
          if (workerSkill > WorkerMaxSkill)
          [ set workerSkill WorkerMaxSkill]

          ; Set the workerReputation that has been calculated.
          set workerReputation workerReputation + tmpTaskReputation

          ; The workerReputation cannot be higher than WorkerMaxReputation.
          if (workerReputation > WorkerMaxReputation)
          [ set workerReputation WorkerMaxReputation]

          ; The workerReputation cannot be lower than 1.
          if (workerReputation < 1)
          [ set workerReputation 1]

          ; In the real world, workers need to be motivated with some reward. For debuggig  purposes,  we
          ; can turn off the motivation verification.
          if (not ForceEndlessMotivation)
          [
            ; The reward increases the worker's motivation.
            set workerMotivation workerMotivation + tmpTaskReward

            ; The workerMotivation cannot be higher than WorkerMaxMotivation.
            if (workerMotivation > WorkerMaxMotivation)
            [ set workerMotivation WorkerMaxMotivation ]

            ; Updates the worker's motivation label being shown in the simulation.
            set label workerMotivation
          ]
        ]
      ]
    ]
  ]

end

;;--------------------------------------------------------------------------------------------------------

; Procedure to move workers in the simulation environment.
to MoveWorker

  ask workers
  [
    ; If SearchNearestTask is true, workers should move towards the task assigned to them. If no task has
    ; been assigned, workers should keep moving randomly until they find a task that they can be assigned
    ; to.
    if (SearchNearestTask = true)
    [
      ; If a worker has a task_link to a task, he should turn to the task pointed by the  task_link. Note
      ; that this simulation allows only one task_link per worker per task. If a worker has no  task_link,
      ; he should be keep moving randomly until he finds a task that can be assigned to.
      ifelse (any? out-task_link-neighbors)
      [
        face one-of out-task_link-neighbors
      ]
      [
        ifelse (random 100 >= 50)
        [ left random Degrees ]
        [ right random Degrees ]
      ]
    ]

    ; If SearchNearestTask is false, workers should move randomly and execute the first task they find on
    ; their way.
    if (SearchNearestTask = false)
    [
      ; This piece of code kill all existing links if SearchNearestTask is turned from true to  false  in
      ; the middle of an ongoing simulation.
      if (any? out-task_link-neighbors)
      [
        ask out-task_link-neighbors
        [ die ]
      ]

      ifelse (random 100 >= 50)
      [ left random Degrees ]
      [ right random Degrees ]
    ]

    forward 1

    ; This piece of code turns the workers' coordinates into a integer value, instead of a floating point
    ; value. If workers move through the patch/environment using floating point  values  they  will  have
    ; problems when trying to match the task coordinates for executing them.
    if (AdjustWorkerStep)
    [ setxy (round xcor) (round ycor) ]

    ; For debugging purposes, it is possible to force the workers' motivation. If  ForceEndlessMotivation
    ; is true, the workerMotivation value will not be decreased.
    if (ForceEndlessMotivation = true)
    [ set label "" ]

    ; If ForceEndlessMotivation is false, the workerMotivation value will be decreased. The only  way  to
    ; increase the workers' motivation is by rewarding them after the execution of a task.
    if (ForceEndlessMotivation = false)
    [
      set workerMotivation workerMotivation - 1

      ; If the worker's motivation is higher than "0", the workers stays in the crowdsourcing environment.
      if (workerMotivation > 0)
      [
        set label workerMotivation
      ]

      ; If the worker's motivation is "0", the workers leave the crowdsourcing environment.
      if (workerMotivation <= 0)
      [ die ]
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
204
10
764
571
-1
-1
16.73
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
767
505
880
538
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
767
538
825
571
Execute
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
825
538
880
571
Step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
7
428
198
461
InitialWorkersAmount
InitialWorkersAmount
1
1000
1.0
1
1
u
HORIZONTAL

SLIDER
7
462
198
495
InitialTasksAmount
InitialTasksAmount
1
1000
245.0
1
1
u
HORIZONTAL

MONITOR
767
28
881
73
Workers
count workers
2
1
11

MONITOR
767
115
881
160
Executed Tasks
globalExecutedTasks
2
1
11

MONITOR
767
71
881
116
Active Tasks
count tasks
2
1
11

SWITCH
8
30
199
63
ShowWorkersPath
ShowWorkersPath
1
1
-1000

SWITCH
8
69
199
102
SearchNearestTask
SearchNearestTask
1
1
-1000

SLIDER
8
101
199
134
Degrees
Degrees
15
180
30.0
15
1
degree
HORIZONTAL

TEXTBOX
9
10
186
28
Workers Setup Controls
11
0.0
1

TEXTBOX
8
410
183
428
Initial Workers and Tasks Amounts
11
0.0
1

SWITCH
381
601
562
634
ShowWorkerSplotch
ShowWorkerSplotch
1
1
-1000

SLIDER
8
143
199
176
WorkerTaskPerceptionRadius
WorkerTaskPerceptionRadius
1
15
4.0
1
1
u
HORIZONTAL

TEXTBOX
208
583
371
601
Tasks Recriation Controls
11
0.0
1

SWITCH
570
634
751
667
ForceEndlessMotivation
ForceEndlessMotivation
1
1
-1000

SWITCH
381
634
562
667
ShowTaskSplotch
ShowTaskSplotch
1
1
-1000

SWITCH
570
601
751
634
ShowWorkerLinkedTask
ShowWorkerLinkedTask
1
1
-1000

SLIDER
205
700
357
733
AddNewWorkersRate
AddNewWorkersRate
0
100
0.0
5
1
%
HORIZONTAL

SLIDER
205
601
357
634
AddNewTasksRate
AddNewTasksRate
0
100
0.0
5
1
%
HORIZONTAL

TEXTBOX
769
10
846
28
Amounts
11
0.0
1

TEXTBOX
769
308
919
326
Workers Averages
11
0.0
1

TEXTBOX
770
177
920
195
Tasks Averages
11
0.0
1

MONITOR
768
199
880
244
Difficulty
mean [taskDifficulty] of tasks
2
1
11

MONITOR
767
245
880
290
Reward
mean [taskReward] of tasks
2
1
11

MONITOR
767
421
880
466
Reputation
mean [workerReputation] of workers
2
1
11

MONITOR
767
331
880
376
Motivation
mean [workerMotivation] of workers
2
1
11

MONITOR
767
376
880
421
Skill
mean [workerSkill] of workers
2
1
11

TEXTBOX
205
680
355
698
Workers Recriation Controls
11
0.0
1

TEXTBOX
383
583
533
601
Debug Controls
11
0.0
1

PLOT
921
26
1316
218
Remaining Tasks x Workers Amount
ticks
amount
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Tasks" 1.0 0 -13345367 true "" "plot count tasks"
"Workers" 1.0 0 -2674135 true "" "plot count workers"

PLOT
921
419
1316
611
Task Difficulty x Task Reward
ticks
u
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Difficulty" 1.0 0 -2674135 true "" "if count workers != 0\n[plot mean [taskDifficulty] of tasks]\n"
"Reward" 1.0 0 -10899396 true "" "if count workers != 0\n[plot mean [taskReward] of tasks]\n"

TEXTBOX
10
506
160
524
Amount of Ticks per Simulation
11
0.0
1

PLOT
921
220
1316
417
Worker Motivation x Skill x Reputation
ticks
amount
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Motivation" 1.0 0 -2674135 true "" "if count workers != 0\n[plot mean [workerMotivation] of workers]\n"
"Skill" 1.0 0 -10899396 true "" "if count workers != 0\n[plot mean [workerSkill] of workers]\n"
"Reputation" 1.0 0 -13345367 true "" "if count workers != 0\n[plot mean [workerReputation] of workers]\n"

SLIDER
8
257
199
290
WorkerMaxReputation
WorkerMaxReputation
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
8
189
199
222
WorkerMaxMotivation
WorkerMaxMotivation
1
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
8
223
199
256
WorkerMaxSkill
WorkerMaxSkill
1
100
100.0
1
1
NIL
HORIZONTAL

TEXTBOX
9
307
190
325
Task Setup Controls
11
0.0
1

SLIDER
7
329
199
362
TaskMaxDifficulty
TaskMaxDifficulty
1
100
1.0
1
1
NIL
HORIZONTAL

SLIDER
7
364
199
397
TaskMaxReward
TaskMaxReward
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
8
563
197
596
MaxSimulationTicks
MaxSimulationTicks
100
10000
100.0
100
1
NIL
HORIZONTAL

SLIDER
205
734
357
767
NewWorkersAmount
NewWorkersAmount
0
30
0.0
5
1
NIL
HORIZONTAL

SLIDER
205
635
357
668
NewTasksAmount
NewTasksAmount
0
30
0.0
5
1
NIL
HORIZONTAL

PLOT
1330
21
1725
218
Remaining Tasks x Motivation
ticks
amount
0.0
100.0
0.0
500.0
true
true
"" ""
PENS
"Tasks" 1.0 0 -13345367 true "" "plot count tasks"
"Motivation" 1.0 0 -2674135 true "" "if count workers != 0\n[plot mean [workerMotivation] of workers]"

SWITCH
570
682
806
715
AvoidTaskExecutionConcurrence
AvoidTaskExecutionConcurrence
0
1
-1000

SWITCH
570
716
806
749
AdjustWorkerStep
AdjustWorkerStep
0
1
-1000

SWITCH
767
469
880
502
debug
debug
1
1
-1000

SWITCH
8
528
197
561
EnableTickCount
EnableTickCount
1
1
-1000

CHOOSER
8
600
197
645
SkillLearningCurveType
SkillLearningCurveType
"Linear" "Ln" "Sigmoid"
0

PLOT
1331
420
1726
617
plot 1
Workers
Tasks
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "plotxy (count workers) (count tasks)"

CHOOSER
379
702
560
747
MaximizationCriterium
MaximizationCriterium
"None" "Motivation" "Skill" "Reputation"
0

PLOT
1331
221
1725
417
motivation histogram
workers
motivation
0.0
5.0
0.0
5.0
true
false
"set-histogram-num-bars 50" "histogram [ workerMotivation ] of workers"
PENS
"default" 1.0 1 -13345367 true "" ""

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
