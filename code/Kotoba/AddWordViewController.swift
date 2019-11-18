//
//  AddWordViewController.swift
//  Kotoba
//
//  Created by Will Hains on 06/17.
//  Copyright © 2016 Will Hains. All rights reserved.
//

import Foundation
import UIKit

final class AddWordViewController: UIViewController
{
	@IBOutlet weak var textField: UITextField!
	
	deinit
	{
		NotificationCenter.default.removeObserver(self)
	}
	
	override func viewDidLoad()
	{
		super.viewDidLoad()
		prepareKeyboardAvoidance()
		
		let titleFont = UIFont.systemFont(ofSize: 22.0, weight: .bold)
		let titleColor = UIColor.init(named: "appHeader") ?? UIColor.label
		self.navigationController?.navigationBar.titleTextAttributes = [ .font: titleFont, .foregroundColor: titleColor ]
	}
	
	override func viewWillAppear(_ animated: Bool) {
		debugLog()
		super.viewWillAppear(animated)
		showKeyboard()
	}
}

// MARK:- Keyboard avoiding
// Solution adapted from http://stackoverflow.com/a/16044603/554518
extension AddWordViewController
{
	func prepareKeyboardAvoidance()
	{
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(AddWordViewController.keyboardWillShow(notification:)),
			name:UIResponder.keyboardWillShowNotification,
			object: nil);
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(AddWordViewController.keyboardWillHide(notification:)),
			name:UIResponder.keyboardWillHideNotification,
			object: nil);
	}

	@objc func keyboardWillShow(notification: Notification)
	{
		let info = notification.userInfo!
		let keyboardSize = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.height
		additionalSafeAreaInsets.bottom = keyboardSize

		let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
		UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
	}

	@objc func keyboardWillHide(notification: Notification)
	{
		let info = notification.userInfo!
		additionalSafeAreaInsets.bottom = 0

		let duration: TimeInterval = (info[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
		UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
	}
}

// MARK:- Show keyboard on launch
extension AddWordViewController
{
	func showKeyboard()
	{
		self.textField.becomeFirstResponder()
	}
}

// MARK:- Text Field delegate
extension AddWordViewController: UITextFieldDelegate
{
	func textFieldShouldReturn(_ textField: UITextField) -> Bool
	{
		if let text = textField.text {
			let word = Word.init(text: text)
			debugLog("word = \(word)")
			
			// NOTE: On iOS 13, UIReferenceLibraryViewController got slow, both to return a view controller and do
			// a definition lookup. Previously, Kotoba did both these things at the same time on the same queue.
			//
			// The gymnastics below are to hide the slowness: after the view controller is presented, the definition lookup
			// proceeds on a background queue. If there's a definition, the text field is cleared: if you spend little time
			// reading the definition, you'll notice that the field is cleared while you're looking at it. If you're really
			// quick, you can see it not appear in the History view, too. Better this than slowness.
			
			self.showDefinition(forWord: word, completion: {
				debugLog("presented dictionary view controlller")
				
				DispatchQueue.global().async {
					debugLog("checking definition")
					let hasDefinition = UIReferenceLibraryViewController.dictionaryHasDefinition(forTerm: word.text)
					debugLog("hasDefinition = \(hasDefinition)")
					if hasDefinition {
						words.add(word: word)
						DispatchQueue.main.async {
							textField.text = nil
						}
					}
				}
			})
		}
		
		return true
	}
	
}
