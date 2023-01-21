//
//  FoldersTableVC.swift
//  FlashWords
//
//  Created by Ирина Кольчугина on 05.01.2023.
//

import UIKit
import SnapKit
import Combine
import SwiftExtension

final class FoldersTableVC: UIViewController {
    private let viewModel: FoldersTableViewModel = .init()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = Titles.folders
        titleLabel.font = .avenirBold28
        titleLabel.textColor = Asset.hexFCFCFC.color
        return titleLabel
    }()

    private lazy var addListButton: UIButton = {
        let addListButton = UIButton()
        addListButton.setImage(Images.plus, for: .normal)
        addListButton.tintColor = Asset.hexFCFCFC.color
        addListButton.addTarget(
            self,
            action: #selector(setAddNewList),
            for: .touchUpInside)
        return addListButton
    }()

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.register(
            FolderTableViewCell.self,
            forCellReuseIdentifier: FolderTableViewCell.withReuseIdentifier)
        tableView.backgroundColor = .clear
        tableView.bounces = true
        tableView.separatorStyle = .none
        return tableView
    }()

    private lazy var newFolderTextField: UITextField = {
        let newFolderTextField = UITextField()
        newFolderTextField.backgroundColor = .clear
        newFolderTextField.font = .avenirBold28
        newFolderTextField.textColor = Asset.hexFCFCFC.color
        newFolderTextField.delegate = self
        newFolderTextField.isUserInteractionEnabled = false
        newFolderTextField.returnKeyType = .done
        newFolderTextField.enablesReturnKeyAutomatically = true
        return newFolderTextField
    }()

    private var actionObserver: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Asset.hex333337.color
        navigationItem.titleView = UIView()
        setupViews()
        setupConstraints()
        setupObserver()
    }

    override func viewWillAppear(_ animated: Bool) {
        viewModel.setUpdateData()
    }

    private func setupViews() {
        view.addSubview(titleLabel)
        view.addSubview(addListButton)
        view.addSubview(tableView)
        view.addSubview(newFolderTextField)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(16)
        }

        newFolderTextField.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(50)
            make.leading.top.height.equalTo(titleLabel)
        }

        addListButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(titleLabel.snp.centerY)
            make.height.width.equalTo(30)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview()
        }
    }

    private func setupObserver() {
        actionObserver = viewModel
            .$mainThreadActionState
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .subscriptionAction:
                    break
                case .reloadData:
                    UIView.transition(
                        with: self.tableView,
                        duration: 0.1,
                        options: .transitionCrossDissolve,
                        animations: { [weak self] in
                            self?.tableView.reloadData()
                        }, completion: nil)
                }
            })
    }

    @objc private func setAddNewList() {
        if addListButton.currentImage == Images.plus {
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self = self else { return }
                self.addListButton.setImage(Images.checkmark, for: .normal)
                self.titleLabel.text = Titles.newFolderName
                self.titleLabel.textColor = Asset.hex5E5E69.color
                self.newFolderTextField.alpha = 1
                self.view.layoutIfNeeded()
            }
            newFolderTextField.isUserInteractionEnabled = true
            newFolderTextField.becomeFirstResponder()
        } else {
            if let textFieldText = newFolderTextField.text?.textWithoutSpacePrefix(),
               textFieldText != .empty {
                viewModel.setSaveNewFolder(name: textFieldText)
            }
            UIView.animate(withDuration: 0.1) { [weak self] in
                guard let self = self else { return }
                self.addListButton.setImage(Images.plus, for: .normal)
                self.newFolderTextField.alpha = 0
                self.titleLabel.text = Titles.folders
                self.titleLabel.textColor = Asset.hexFCFCFC.color
                self.titleLabel.alpha = 1
                self.view.layoutIfNeeded()
            }
            newFolderTextField.text = .empty
            newFolderTextField.isUserInteractionEnabled = false
            view.endEditing(true)
        }
    }

}

extension FoldersTableVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.foldersData.count.sum(1)
    }

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return 1
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FolderTableViewCell.withReuseIdentifier,
            for: indexPath) as? FolderTableViewCell else {
            return .init(frame: .zero)
        }
        if indexPath.section == 0 {
            let allWordCount = viewModel.foldersData.reduce(0) { partialResult, folderInfo in
                let result = partialResult.sum(folderInfo.wordsModel.count)
                return result
            }
            cell.setupView(viewModel: .init(
                name: Titles.allWords, 
                wordsCount: allWordCount))
        } else {
            let folderInfo = (viewModel.foldersData[safe: indexPath.section.subtraction(1)]).nonOptional(.emptyModel)
            cell.setupView(viewModel: .init(
                name: folderInfo.folderName,
                wordsCount: folderInfo.wordsModel.count))
        }

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        viewForFooterInSection section: Int
    ) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .clear
        return headerView
    }

    func tableView(
        _ tableView: UITableView,
        heightForFooterInSection section: Int
    ) -> CGFloat {
        return 10
    }

    func tableView(
        _ tableView: UITableView,
        editingStyleForRowAt indexPath: IndexPath
    ) -> UITableViewCell.EditingStyle {
        guard indexPath.section != 0 else {
            return .none
        }
        return .delete
    }

    func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard indexPath.section != 0 else {
            return
        }
        viewModel.setDeleteFolder(index: indexPath.section.subtraction(1))
    }
}

extension FoldersTableVC: UITableViewDelegate {
    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        view.endEditing(true)
        if indexPath.section != 0 {
            viewModel.setSelectFolder(index: indexPath.section.subtraction(1))
        }
        navigationController?.pushViewController(WordListTableVC(), animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 50.0
    }

}

extension FoldersTableVC: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let text = textField.text?.textWithoutSpacePrefix(),
              !text.contains(Symbols.returnCommand) else {
            let clearText = textField.text?.textWithoutSpacePrefix().replacingOccurrences(
                of: Symbols.returnCommand,
                with: String.empty)
            textField.text = clearText
            view.endEditing(true)
            return
        }

        textField.text = text
        titleLabel.alpha = Ternary.get(
            if: .value(text == .empty),
            true: .value(1),
            false: .value(0))
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setAddNewList()
        view.endEditing(true)
        return true
    }

}
