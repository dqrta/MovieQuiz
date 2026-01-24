import UIKit


final class MovieQuizViewController: UIViewController, MovieQuizViewControllerProtocol {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var questionImageView: UIImageView!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    
    private var presenter: MovieQuizPresenter!
    private var alertPresenter: ResultAlertPresenter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupDependencies()
    }
    
    private func setupUI() {
        questionImageView.layer.cornerRadius = 20
        imageActivityIndicator.startAnimating()
        activityIndicator.startAnimating()
        showLoadingIndicator()
    }
    
    private func setupDependencies() {
        presenter = MovieQuizPresenter(viewController: self)
        alertPresenter = ResultAlertPresenter()
    }
    
    func show(quiz step: QuizStepViewModel) {
        questionImageView.image = UIImage(data: step.image) ?? UIImage()
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
        imageActivityIndicator.isHidden = true
        self.setEnabledButtons(state: true)
    }
    
    func show(quiz result: QuizResultsViewModel) {
        let model = AlertModel(title: result.title, message: presenter.makeResultsMessage(), buttonText: result.buttonText) { [weak self] in
            guard let self = self else { return }
            
            presenter.restartGame()
            questionImageView.layer.borderWidth = 0
            questionImageView.layer.borderColor = nil
            
            presenter.questionFactory?.requestNextQuestion()
            self.imageActivityIndicator.isHidden = false
        }
        alertPresenter?.show(in: self, model: model)
    }
    
    func highlightImageBorder(isCorrectAnswer: Bool) {
        questionImageView.layer.borderWidth = 8
        questionImageView.layer.borderColor = isCorrectAnswer ? UIColor.ypGreen.cgColor : UIColor.ypRed.cgColor
        
        self.setEnabledButtons(state: false)
    }
    
    func setEnabledButtons(state isEnabled: Bool) {
        noButton.isEnabled = isEnabled
        yesButton.isEnabled = isEnabled
    }
    
    
    func showLoadingIndicator() {
        activityIndicator.isHidden = false
    }
    
    func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    func showNetworkError(message: String) {
        let model = AlertModel(title: "Ошибка",
                               message: message,
                               buttonText: "Попробовать еще раз",
                               completion: {[weak self] in
            guard let self = self else {return}
            self.presenter.restartGame()
            presenter.questionFactory?.loadData()
        })
        
        alertPresenter?.show(in: self, model: model)
    }
    
    
    @IBAction private func buttonClicked(_ sender: UIButton) {
        presenter.buttonClicked(clicked: sender.tag != 0)
    }
    
    @IBAction private func buttonPushed(_ sender: Any) {
        setEnabledButtons(state: false)
    }
    @IBAction private func buttonDragOutside(_ sender: Any) {
        setEnabledButtons(state: true)
    }
}


