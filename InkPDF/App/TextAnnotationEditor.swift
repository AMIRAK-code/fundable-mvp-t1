//
//  TextAnnotationEditor.swift
//  InkPDF
//
//  Small sheet for creating/editing typed text boxes on a page:
//  text, font size, and color, with Delete for existing notes.
//

import UIKit

final class TextAnnotationEditorViewController: UIViewController {

    enum Result {
        case commit(text: String, fontSize: CGFloat, color: UIColor)
        case delete
        case cancel
    }

    var onFinish: ((Result) -> Void)?

    private let isNewAnnotation: Bool
    private var fontSize: CGFloat
    private var color: UIColor

    private let textView = UITextView()
    private let sizeLabel = UILabel()
    private let colorWell = UIColorWell()

    init(text: String, fontSize: CGFloat, color: UIColor, isNewAnnotation: Bool) {
        self.fontSize = fontSize
        self.color = color
        self.isNewAnnotation = isNewAnnotation
        super.init(nibName: nil, bundle: nil)
        textView.text = text
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = isNewAnnotation ? "New Text" : "Edit Text"

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(cancelTapped))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                            target: self,
                                                            action: #selector(doneTapped))

        textView.font = .systemFont(ofSize: 20)
        textView.layer.cornerRadius = 10
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.separator.cgColor
        textView.backgroundColor = .secondarySystemBackground
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)

        let stepper = UIStepper()
        stepper.minimumValue = 8
        stepper.maximumValue = 72
        stepper.stepValue = 2
        stepper.value = Double(fontSize)
        stepper.addTarget(self, action: #selector(sizeChanged(_:)), for: .valueChanged)

        sizeLabel.text = "Size: \(Int(fontSize)) pt"
        sizeLabel.font = .preferredFont(forTextStyle: .subheadline)

        colorWell.selectedColor = color
        colorWell.supportsAlpha = false
        colorWell.addTarget(self, action: #selector(colorChanged(_:)), for: .valueChanged)

        let colorLabel = UILabel()
        colorLabel.text = "Color"
        colorLabel.font = .preferredFont(forTextStyle: .subheadline)

        let controlsRow = UIStackView(arrangedSubviews: [sizeLabel, stepper, UIView(), colorLabel, colorWell])
        controlsRow.axis = .horizontal
        controlsRow.spacing = 12
        controlsRow.alignment = .center

        let stack = UIStackView(arrangedSubviews: [textView, controlsRow])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            textView.heightAnchor.constraint(equalToConstant: 140)
        ])

        if !isNewAnnotation {
            let deleteButton = UIButton(type: .system)
            deleteButton.setTitle("Delete Text Box", for: .normal)
            deleteButton.setTitleColor(.systemRed, for: .normal)
            deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
            stack.addArrangedSubview(deleteButton)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }

    @objc private func sizeChanged(_ sender: UIStepper) {
        fontSize = CGFloat(sender.value)
        sizeLabel.text = "Size: \(Int(fontSize)) pt"
    }

    @objc private func colorChanged(_ sender: UIColorWell) {
        color = sender.selectedColor ?? color
    }

    @objc private func doneTapped() {
        let text = textView.text ?? ""
        let size = fontSize
        let chosenColor = color
        let handler = onFinish
        dismiss(animated: true) {
            handler?(.commit(text: text, fontSize: size, color: chosenColor))
        }
    }

    @objc private func deleteTapped() {
        let handler = onFinish
        dismiss(animated: true) {
            handler?(.delete)
        }
    }

    @objc private func cancelTapped() {
        let handler = onFinish
        dismiss(animated: true) {
            handler?(.cancel)
        }
    }

    /// Wrap in a navigation controller, configured as a medium-detent sheet.
    func wrappedInSheet() -> UINavigationController {
        let navigation = UINavigationController(rootViewController: self)
        if let sheet = navigation.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        return navigation
    }
}
