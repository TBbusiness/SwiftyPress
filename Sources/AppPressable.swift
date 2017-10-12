//
//  UIApplicationDelegate.swift
//  SwiftyPress
//
//  Created by Basem Emara on 5/6/16.
//
//

import Foundation
import ZamzamKit
import JASON
import UserNotifications
import RealmSwift
import Alamofire

public protocol AppPressable: Navigable, UNUserNotificationCenterDelegate {
    var window: UIWindow? { get set }
    var urlSessionManager: SessionManager? { get set }
}

public extension AppPressable where Self: UIApplicationDelegate {

    /**
     Configures application for currently launched site.

     - parameter application: Singleton app object.
     - parameter launchOptions: A dictionary indicating the reason the app was launched (if any).

     - returns: False if the app cannot handle the URL resource or continue a user activity, otherwise return true. The return value is ignored if the app is launched as a result of a remote notification.
     */
    func didFinishLaunchingSite(_ application: UIApplication, launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Log(info: "AppPressable.didFinishLaunchingSite started.")
        application.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        UNUserNotificationCenter.current().register(
            delegate: self,
            actions: [UNNotificationAction(identifier: "favorite", title: .localized(.favorite))]
        )
        
        // Initialize Google Analytics
        if !AppGlobal.userDefaults[.googleAnalyticsID].isEmpty {
            GAI.sharedInstance().tracker(
                withTrackingId: AppGlobal.userDefaults[.googleAnalyticsID])
        }
        
        // Declare data format from remote REST API
        JSON.dateFormatter.dateFormat = ZamzamConstants.DateTime.JSON_FORMAT
        
        // Initialize components
        _ = AppLogger()
        _ = AppData()
        
        // Select home tab
        (window?.rootViewController as? UITabBarController)?.selectedIndex = 2
        
        setupTheme()
        
        Log(info: "SwiftyPress finish launching.")
        
        // Handle shortcut launch
        if let shortcutItem = launchOptions?[.shortcutItem] as? UIApplicationShortcutItem {
            performActionForShortcutItem(application, shortcutItem: shortcutItem)
            return false
        }
    
        return true
    }
    
    /**
     Tells the delegate that the data for continuing an activity is available.

     - parameter application: Your shared app object.
     - parameter userActivity: The activity object containing the data associated with the task the user was performing. Use the data in this object to recreate what the user was doing.
     - parameter restorationHandler: A block to execute if your app creates objects to perform the task. Calling this block is optional and you can copy this block and call it at a later time. When calling a saved copy of the block, you must call it from the app’s main thread.

     - returns: True to indicate that your app handled the activity or false to let iOS know that your app did not handle the activity.
     */
    func continueUserActivity(_ application: UIApplication, userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let webpageURL = userActivity.webpageURL else { return false }
        Log(info: "AppPressable.continueUserActivity for URL: \(webpageURL.absoluteString).")
        return navigateByURL(webpageURL)
    }
    
    /// Tells the app that it can begin a fetch operation if it has data to download.
    ///
    /// - Parameters:
    ///   - application: Your shared app object.
    ///   - completionHandler: The block to execute when the download operation is complete.
    func performFetch(_ application: UIApplication, completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Log(info: "AppPressable.performFetch started.")
        scheduleUserNotifications(completionHandler: completionHandler)
    }
    
    func performActionForShortcutItem(_ application: UIApplication, shortcutItem: UIApplicationShortcutItem, completionHandler: ((Bool) -> Void)? = nil) {
        window?.rootViewController?.dismiss(animated: false, completion: nil)
        guard let tabController = window?.rootViewController as? UITabBarController else { completionHandler?(false); return }
        
        switch shortcutItem.type {
        case "favorites":
            tabController.selectedIndex = 0
        case "search":
            tabController.selectedIndex = 3
        case "contact":
            guard let url = URL(string: "mailto:\(AppGlobal.userDefaults[.email])") else { break }
            UIApplication.shared.open(url)
        default: break
        }
        
        completionHandler?(true)
    }
}


// MARK: - Internal functions
private extension AppPressable {

    func setupTheme() {
        window?.tintColor = UIColor(rgb: AppGlobal.userDefaults[.tintColor])
        
        if !AppGlobal.userDefaults[.titleColor].isEmpty {
            UINavigationBar.appearance().titleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor(rgb: AppGlobal.userDefaults[.titleColor])
            ]
        }
        
        // Configure tab bar
        if let controller = window?.rootViewController as? UITabBarController {
            controller.tabBar.items?.get(1)?.image = UIImage(named: "top-charts", inBundle: AppConstants.bundle)
            controller.tabBar.items?.get(1)?.selectedImage = UIImage(named: "top-charts-filled", inBundle: AppConstants.bundle)
            controller.tabBar.items?.get(2)?.image = UIImage(named: "explore", inBundle: AppConstants.bundle)
            controller.tabBar.items?.get(2)?.selectedImage = UIImage(named: "explore-filled", inBundle: AppConstants.bundle)
            
            if !AppGlobal.userDefaults[.tabTitleColor].isEmpty {
                UITabBarItem.appearance().setTitleTextAttributes([
                    NSAttributedStringKey.foregroundColor: UIColor(rgb: AppGlobal.userDefaults[.tabTitleColor])
                ], for: .selected)
           }
        }
        
        // Configure dark mode if applicable
        if AppGlobal.userDefaults[.darkMode] {
            UINavigationBar.appearance().barStyle = .black
            UITabBar.appearance().barStyle = .black
            UICollectionView.appearance().backgroundColor = .black
            UITableView.appearance().backgroundColor = .black
            UITableViewCell.appearance().backgroundColor = .clear
        }
    }
}

// MARK: - User Notification Delegate
extension AppPressable {

    public func didReceiveUserNotification(response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        guard let id = response.notification.request.content.userInfo["id"] as? Int,
            let link = response.notification.request.content.userInfo["link"] as? String,
            let url = try? link.asURL()
                else { return }
        
        switch response.actionIdentifier {
        case UNNotificationDefaultActionIdentifier: _ = navigateByURL(url)
        case "favorite": PostService().addFavorite(id)
        case "share": _ = navigateByURL(url)
        default: break
        }
        
        completionHandler()
    }
    
    fileprivate func scheduleUserNotifications(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Get latest posts from server
        // Persist network manager instance to ensure lifespan is not interrupted
        urlSessionManager = PostService().updateFromRemote {
            guard case .success(let results) = $0 else { return completionHandler(.failed) }
            
            guard let id = results.created.first,
                let post = (try? Realm())?.object(ofType: Post.self, forPrimaryKey: id)
                    else { return completionHandler(.noData) }
            
            var attachments = [UNNotificationAttachment]()
            
            // Completion process on exit
            func deferred() {
                // Launch notification
                UNUserNotificationCenter.current().add(
                    body: post.previewContent,
                    title: post.title,
                    attachments: attachments,
                    timeInterval: 5,
                    userInfo: [
                        "id": post.id,
                        "link": post.link
                    ],
                    completion: {
                        guard $0 == nil else { return Log(error: "Could not schedule the notification for the post: \($0.debugDescription).") }
                        Log(debug: "Scheduled notification for post during background fetch.")
                    }
                )
                
                completionHandler(.newData)
            }
            
            // Get remote media to attach to notification
            guard let link = post.media?.thumbnailLink else { return deferred() }
            let thread = Thread.current
            
            UNNotificationAttachment.download(from: link) {
                defer { thread.async { deferred() } }
                
                guard $0.isSuccess, let attachment = $0.value else {
                    return Log(error: "Could not download the post thumbnail (\(link)): \($0.error.debugDescription).")
                }
                
                // Store attachment to schedule notification later
                attachments.append(attachment)
            }
        }
    }
}
