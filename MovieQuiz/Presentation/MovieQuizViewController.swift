import UIKit


final class MovieQuizViewController: UIViewController {
    
    private enum Strings {
        static let correctAnswersText = "Вы ответили правильно на %d вопрос(ов) из %d\n" +
                                        "Всего игр: %d\n" +
                                        "Рекорд: %d/%d (%@)\n" +
                                        "Ваша статистика: %.2f %%"
        static let roundOverText = "Раунд окончен"
        static let retryText = "Сыграть еще раз!"
    }
    
    private var correctAnswers: Int = 0
    private var currentQuestionIndex: Int = 0
    private var questionsAmount: Int = 10
    
    private var questionFactory: QuestionFactoryProtocol?
    private var alertPresenter: ResultAlertPresenter?
    private var statisticService: StatisticServiceProtocol?
    private var currentQuestion: QuizQuestion?
    
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    @IBOutlet private weak var questionImageView: UIImageView!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let questionFactory = QuestionFactory()
        questionFactory.delegate = self
        self.questionFactory = questionFactory
        
        self.statisticService = StatisticService()
        self.alertPresenter = ResultAlertPresenter()
        
        self.questionFactory?.requestNextQuestion()
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        let questionStep = QuizStepViewModel(
            image: UIImage(named: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
        return questionStep
    }
    
    private func show(quiz step: QuizStepViewModel) {
        questionImageView.image = step.image
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func show(quiz result: QuizResultsViewModel) {
        let model = AlertModel(title: result.title, message: result.text, buttonText: result.buttonText) { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            questionImageView.layer.borderWidth = 0
            questionImageView.layer.borderColor = nil
            self.questionFactory?.requestNextQuestion()
        }
        
        alertPresenter?.show(in: self, model: model)
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        questionImageView.layer.borderWidth = 8
        questionImageView.layer.borderColor = isCorrect ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        self.setEnabledButtons(state: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.showNextQuestionOrResults()
            self.setEnabledButtons(state: true)
        }
    }
    
    private func setEnabledButtons(state isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    private func showNextQuestionOrResults() {
        if currentQuestionIndex == questionsAmount - 1 {
            let gameResult = GameResult(correct: correctAnswers, total: questionsAmount, date: Date())
            guard let statisticService = statisticService else { return }
            statisticService.store(gameResult)
            let bestGame = statisticService.bestGame
            let viewModel = QuizResultsViewModel(
                title: Strings.roundOverText,
                text: String(format: Strings.correctAnswersText,
                             correctAnswers,
                             questionsAmount,
                             statisticService.gamesCount,
                             bestGame.correct,
                             bestGame.total ,
                             bestGame.date.dateTimeString,
                             statisticService.totalAccuracy),
                buttonText: Strings.retryText)
                
            show(quiz: viewModel)
        } else {
            currentQuestionIndex += 1
            
            questionImageView.layer.borderColor = nil
            questionImageView.layer.borderWidth = 0
            
            questionFactory?.requestNextQuestion()
        }
    }
    
    @IBAction private func yesButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: currentQuestion.correctAnswer)
    }
    
    @IBAction private func noButtonClicked(_ sender: Any) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        showAnswerResult(isCorrect: !currentQuestion.correctAnswer)
    }
    
    @IBAction func yesButtonPushed(_ sender: Any) {
        setEnabledButtons(state: false)
    }
    @IBAction func noButtonPushed(_ sender: Any) {
        setEnabledButtons(state: false)
    }
    @IBAction func yesButtonDragOutside(_ sender: Any) {
        setEnabledButtons(state: true)
    }
    @IBAction func noButtonDragOutside(_ sender: Any) {
        setEnabledButtons(state: true)
    }
}

extension MovieQuizViewController: QuestionFactoryDelegate {
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        currentQuestion = question
        let viewModel = convert(model: question)
        show(quiz: viewModel)
    }
}
