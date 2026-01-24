import Foundation

struct QuizStepViewModel {
    let image: Data
    let question: String
    let questionNumber: String
}

final class MovieQuizPresenter {
    private enum Strings {
        static let roundOverText = "Раунд окончен"
        static let retryText = "Сыграть еще раз!"
    }
    
    
    
    let questionsAmount: Int = 10
    var correctAnswers: Int = 0
    
    private var currentQuestionIndex: Int = 0
    
    var currentQuestion: QuizQuestion?
    var questionFactory: QuestionFactory?
    private let statisticService: StatisticServiceProtocol!
    private weak var viewController: MovieQuizViewController?
    
    init(viewController: MovieQuizViewControllerProtocol) {
        self.viewController = viewController as? MovieQuizViewController
        
        statisticService = StatisticService()
        
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        questionFactory?.loadData()
        viewController.showLoadingIndicator()
    }
    
    func isLastQuestion() -> Bool {
        return currentQuestionIndex == questionsAmount - 1
    }
    
    func resetQuestionIndex() {
        currentQuestionIndex = 0
    }
    
    func switchToNextQuestion() {
        currentQuestionIndex += 1
    }
    
    func restartGame() {
        resetQuestionIndex()
        correctAnswers = 0
    }
    
    func convert(model: QuizQuestion) -> QuizStepViewModel {
        QuizStepViewModel(
            image: model.image,
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)"
        )
    }
    
    func buttonClicked(clicked: Bool) {
        didAnswer(isYes: clicked)
    }
    
    func showNextQuestionOrResults() {
        if self.isLastQuestion() {
            let gameResult = GameResult(correct: self.correctAnswers, total: self.questionsAmount, date: Date())
            guard let statisticService = statisticService else { return }
            statisticService.store(gameResult)
            viewController?.setEnabledButtons(state: false)
            let viewModel = QuizResultsViewModel(
                title: Strings.roundOverText,
                buttonText: Strings.retryText)
            viewController?.show(quiz: viewModel)
        } else {
            viewController?.imageActivityIndicator.isHidden = false
            
            
            self.switchToNextQuestion()
            
            viewController?.questionImageView.layer.borderColor = nil
            viewController?.questionImageView.layer.borderWidth = 0
            
            questionFactory?.requestNextQuestion()
            
        }
    }
    
    func makeResultsMessage() -> String {
        statisticService.store(GameResult(correct: correctAnswers, total: questionsAmount, date: Date()))
        
        let bestGame = statisticService.bestGame
        
        let totalPlaysCountLine = "Количество сыгранных квизов: \(statisticService.gamesCount)"
        let currentGameResultLine = "Ваш результат: \(correctAnswers)\\\(questionsAmount)"
        let bestGameInfoLine = "Рекорд: \(bestGame.correct)\\\(bestGame.total)"
        + " (\(bestGame.date.dateTimeString))"
        let averageAccuracyLine = "Средняя точность: \(String(format: "%.2f", statisticService.totalAccuracy))%"
        
        let resultMessage = [
            currentGameResultLine, totalPlaysCountLine, bestGameInfoLine, averageAccuracyLine
        ].joined(separator: "\n")
        
        return resultMessage
    }
    
    func showAnswerResult(isCorrect: Bool) {
        if isCorrect {
            correctAnswers += 1
        }
        
        viewController?.highlightImageBorder(isCorrectAnswer: isCorrect)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
        }
    }
    
    private func didAnswer(isYes: Bool) {
        guard let currentQuestion = currentQuestion else {
            return
        }
        
        let givenAnswer = isYes
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
}

extension MovieQuizPresenter: QuestionFactoryDelegate {
    func didLoadDataFromServer() {
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: any Error) {
        viewController?.showLoadingIndicator()
        viewController?.showNetworkError(message: error.localizedDescription)
    }
    
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else {
            return
        }
        
        self.currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {return}
            self.viewController?.show(quiz: viewModel)
            self.viewController?.setEnabledButtons(state: true)
        }
        viewController?.hideLoadingIndicator()
    }
}
