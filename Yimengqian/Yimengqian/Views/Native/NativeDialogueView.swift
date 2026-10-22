// NativeDialogueView.swift
//
// 茶坊对谈页的两个缺口：
// 1) 「对谈记录」点开只弹一行「当前对谈：人生起伏」，看不到内容；
// 2) 话题行点下去，当前回复气泡也不会换（因为换内容需要像素叠层）。
//
// 这里先用一个原生页把内容讲清楚：
// - /native/dialogue/<topicId>：某一话题的完整问答（问题 + 苏轼逐句回复）
// - /native/list/dialogues：三个话题的总览，点开进各自问答
// 等以后做「原位切换」的像素叠层时，这个页面可以继续作为"展开看全文"的入口。

import SwiftUI

struct NativeDialogueView: View {
    let topicID: String

    @EnvironmentObject private var router: Router

    private var topic: DialogueTopic? {
        ContentData.dialogueTopics.first(where: { $0.id == topicID })
    }

    var body: some View {
        ZStack(alignment: .top) {
            Theme.paperWarm.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("对谈")
                        .font(.custom("KaitiSC-Bold", size: 26))
                        .foregroundColor(Theme.ink)
                        .padding(.top, 96)

                    if let topic = topic {
                        Text("你问：\(topic.question)")
                            .font(.custom("KaitiSC-Bold", size: 16))
                            .foregroundColor(Theme.ink)
                            .padding(.bottom, 2)

                        ForEach(topic.responses, id: \.id) { line in
                            bubble(line)
                        }
                    } else {
                        Text("没有找到这段对谈")
                            .font(.custom("SongtiSC-Regular", size: 13))
                            .foregroundColor(Theme.inkMuted)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }

            topBar
        }
    }

    private func bubble(_ line: DialogueLine) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if line.speaker == .character {
                Circle()
                    .fill(Theme.paperLight)
                    .frame(width: 30, height: 30)
                    .overlay(Text("苏").font(.custom("KaitiSC-Bold", size: 14)).foregroundColor(Theme.vermilion))
                    .overlay(Circle().strokeBorder(Theme.goldBorder.opacity(0.5), lineWidth: 0.8))
            }
            Text(line.text)
                .font(.custom("SongtiSC-Regular", size: 14))
                .foregroundColor(Theme.ink)
                .lineSpacing(5)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(line.speaker == .character ? Theme.paperLight : Theme.cardTan.opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Theme.goldBorder.opacity(0.4), lineWidth: 0.8)
                )
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
}
