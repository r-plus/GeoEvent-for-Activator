//
//  AddNewEventViewController.m
//  GeoEvent for Activator
//
//  Created by hyde on 2014/08/17.
//  Copyright (c) 2014年 hyde. All rights reserved.
//

#import "AddNewEventViewController.h"
#import "LocationSettingViewController.h"

@interface AddNewEventViewController ()
@property (strong, nonatomic) UITextField *textField;
@end

@implementation AddNewEventViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 40, 320, 44)];
    self.textField.delegate = self;
    self.textField.backgroundColor = [UIColor whiteColor];
    self.textField.placeholder = @"Event Name";
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15, 44)];
    paddingView.opaque = NO;
    paddingView.backgroundColor = [UIColor clearColor];
    self.textField.leftView = paddingView;
    self.textField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.textField];
    [self.textField becomeFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = @"Event Name";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor colorWithRed:0.96 green:0.96 blue:0.96 alpha:1.0];

    
    UIBarButtonItem *dismissButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                               target:self
                                                                               action:@selector(dismiss:)];
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(next:)];
    self.navigationItem.leftBarButtonItem = dismissButton;
    self.navigationItem.rightBarButtonItem = nextButton;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)next:(id)sender
{
    self.name = self.textField.text;
    LocationSettingViewController *vc = [LocationSettingViewController new];
    vc.isModifyMode = NO;
    vc.radius = 50.0;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - delegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.navigationItem.rightBarButtonItem.enabled = (textField.text.length - range.length + string.length) ? YES : NO;
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length) {
        [self next:nil];
    }
    return YES;
}

@end
