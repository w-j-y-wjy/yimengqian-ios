// NativeProfileEditView.swift
//
// 个人中心的铅笔徽标（avatar 热区）—— 原本只弹「头像修改为原型模拟」，是个假按钮。
//
// 这版做成真的：可改昵称与身份，保存后个人中心上的文字会立刻跟着变。
// 头像图片本身暂不替换 —— 它画在位图里的一个圆形中，需要像素级叠层才能换；
// 页面里明确写清这一点，不做「看起来能换其实没换」的假交互。

import SwiftUI

struct NativeProfileEditView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var toast: ToastCenter

    @State private var name: String = ""
    @State private var title: String = ""

    private let nameLimit = 8
    private let titleLimit = 10
    private let titlePresets = ["江南游学者", "山水闲人", "汴京过客", "听雨居士"]

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("个人资料")
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                        .padding(.top, 96)

                    field("昵称", text: $name, placeholder: "梦客·苏蘅", limit: nameLimit)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("身份")
                            .font(.custom("SongtiSC-Regular", size: 12.5))
                            .foregroundColor(Theme.inkMuted)
                        HStack(spacing: 8) {
                            ForEach(titlePresets, id: \.self) { preset in
                                let isOn = preset == title
                                Button(action: { title = preset }) {
                                    Text(preset)
                                        .font(.custom(isOn ? "KaitiSC-Bold" : "SongtiSC-Regular", size: 12.5))
                                        .foregroundColor(isOn ? Theme.ink : Theme.inkLight)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Capsule().fill(isOn ? Theme.chipTan : Theme.paperLight))
                                        .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(isOn ? 0 : 0.45), lineWidth: 0.8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Text("头像仍使用设计稿里的形象；替换头像需要像素层，暂未开放。")
                        .font(.custom("SongtiSC-Regular", size: 11.5))
                        .foregroundColor(Theme.inkMuted)
                        .lineSpacing(3)

                    Button(action: save) {
                        Text("保存")
                            .font(.custom("SongtiSC-Regular", size: 15))
                            .foregroundColor(Theme.paperWarm)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(Capsule().fill(Theme.vermilion))
                    }
                    .buttonStyle(.plain)

                    Button(action: reset) {
                        Text("恢复默认")
                            .font(.custom("SongtiSC-Regular", size: 13))
                            .foregroundColor(Theme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            topBar
        }
        .onAppear {
            name = store.string(StorageKeys.profileName) ?? ""
            title = store.string(StorageKeys.profileTitle) ?? ""
        }
    }

    private func field(_ label: String, text: Binding<String>, placeholder: String, limit: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.custom("SongtiSC-Regular", size: 12.5))
                    .foregroundColor(Theme.inkMuted)
                Spacer()
                Text("\(text.wrappedValue.count) / \(limit)")
                    .font(.custom("SongtiSC-Regular", size: 11))
                    .foregroundColor(text.wrappedValue.count > limit ? Theme.vermilion : Theme.inkMuted)
            }
            TextField(placeholder, text: text)
                .font(.custom("SongtiSC-Regular", size: 15))
                .foregroundColor(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.paperLight))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Theme.goldBorder.opacity(0.45), lineWidth: 0.8))
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { router.closeNative() }) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                    Text("返回").font(.custom("SongtiSC-Regular", size: 14))
                }
                .foregroundColor(Theme.ink)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Capsule().fill(Theme.paperLight))
                .overlay(Capsule().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 54)
    }

    private func save() {
        let n = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard n.count <= nameLimit else {
            toast.show("昵称最多 \(nameLimit) 个字")
            return
        }
        guard t.count <= titleLimit else {
            toast.show("身份最多 \(titleLimit) 个字")
            return
        }
        store.setString(StorageKeys.profileName, n)
        store.setString(StorageKeys.profileTitle, t)
        toast.show("已保存")
        router.closeNative()
    }

    private func reset() {
        store.remove(StorageKeys.profileName)
        store.remove(StorageKeys.profileTitle)
        name = ""
        title = ""
        toast.show("已恢复默认资料")
    }
}
